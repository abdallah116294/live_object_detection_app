import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:live_object_detection_app/main.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraController cameraController;
  late CameraImage cameraImage;
  bool isWorking = false;
  double? imageHeight;
  double? imageWidth;
  List? recognitionsList;
  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((image) => {
              if (!isWorking)
                {isWorking = true, cameraImage = image, runModelOnFrame()}
            });
      });
    });
  }

  runModelOnFrame() async {
    imageHeight = cameraImage.height + 0.0;
    imageWidth = cameraImage.width + 0.0;
    recognitionsList = await Tflite.detectObjectOnFrame(
        bytesList: cameraImage.planes.map((e) {
          return e.bytes;
        }).toList(),
        model: 'SSDMobileNet',
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResultsPerClass: 1,
        threshold: 0.4);
    isWorking = false;
    setState(() {
      cameraImage;
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      //String response;
      var response = await Tflite.loadModel(
          model: 'assets/ssd_mobilenet.tflite',
          labels: 'assets/ssd_mobilenet.txt');
      print(response);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.stopImageStream();
    Tflite.close();
  }

List<Widget> displyBoxesAroundRecognozedObject(Size screen) {
    if (recognitionsList == null) {
      return [];
    }
    if (imageHeight == null || imageWidth == null) {
      return [];
    }
    double factorx = screen.width;
    double factory = imageHeight!;
    Color orange = Colors.orange;
    return recognitionsList!.map((e) {
      return Positioned(
        left: e['rect']['x'] * factorx,
        top: e['rect']['y'] * factory,
        width: e['rect']['w'] * factorx,
        height: e['rect']['h'] * factory,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange, width: 2.0)),
          child: Text(
            '${e['detectedClass']}${(e['confidenceInClass'] * 100).toString()}%',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildernWidget = [];
    stackChildernWidget.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: Container(
          height: size.height - 100,
          child: (!cameraController.value.isInitialized)
              ? Container()
              : AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
        ),
      ),
    );
    if (cameraImage != null) {
      stackChildernWidget.addAll(displyBoxesAroundRecognozedObject(size));
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          margin: const EdgeInsets.only(top: 10),
          color: Colors.black,
          child: Stack(children: stackChildernWidget),
        ),
      ),
    );
  }
}
