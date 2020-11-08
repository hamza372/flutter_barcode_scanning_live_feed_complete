import 'dart:typed_data';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ScannerUtils.dart';



List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyHomePage(
    title: "MyHomePage",
  ));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage img;
  CameraController controller;
  bool isBusy = false;
  String result = "";
  BarcodeDetector labeler;

  @override
  void initState() {
    super.initState();
    //initializeCamera();
    labeler = FirebaseVision.instance.barcodeDetector();
  }
  initializeCamera () async
  {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

        controller.startImageStream((image) => {
          if (!isBusy)
            {
              isBusy = true,
              img = image,
              doBarcodeScanning()
              // loadFilesOD4()
            }
        });

    });
  }

  @override
  void dispose() {
    controller?.dispose();
    labeler.close();
    super.dispose();
  }



  doBarcodeScanning() async{
    print("in scanning method");
    ScannerUtils.detect(
      image: img,
      detectInImage: labeler.detectInImage,
    ).then(
          (dynamic results) {
            print("result");
            result = "";
            if(results is List<Barcode>){
              List<Barcode> labels = results;
              setState(() {
                for(Barcode barcode in labels){
                  final BarcodeValueType valueType = barcode.valueType;
                  result+=valueType.toString()+"\n";
                  switch (valueType) {
                    case BarcodeValueType.wifi:
                      final String ssid = barcode.wifi.ssid;
                      final String password = barcode.wifi.password;
                      final BarcodeWiFiEncryptionType type = barcode.wifi.encryptionType;
                      result+=ssid+"\n"+password;
                      break;
                    case BarcodeValueType.url:
                      final String title = barcode.url.title;
                      final String url = barcode.url.url;
                      result+=title+"\n"+url;
                      break;
                    case BarcodeValueType.email:
                      result +=barcode.email.body;
                      break;
                  }
                }
              });
            }

      },
    ).whenComplete(() => isBusy = false);
  }
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('images/wall2.jpg'), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Container(
                          margin: EdgeInsets.only(top: 100),
                          height: 220,
                          width: 220,
                          child: Image.asset('images/sframe.jpg')),
                    ),
                    Center(
                      child: FlatButton(
                        child: Container(
                          margin: EdgeInsets.only(top: 108),
                          height: 205,
                          width: 205,
                          child: img == null?Container(
                            width: 140,
                            height: 150,
                            child: Icon(
                              Icons.videocam,
                              color: Colors.black,
                            ),
                          ):AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                        ),
                        onPressed: (){
                            initializeCamera();
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 50),
                    child: SingleChildScrollView(
                        child: Text(
                          '$result',
                          style: TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontFamily: 'finger_paint'),
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}
