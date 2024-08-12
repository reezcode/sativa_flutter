import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sativa_flutter/core/enums/detection_class.dart';
import 'package:sativa_flutter/utils/classifier.dart';
import 'package:sativa_flutter/utils/isolate_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController cameraController;
  Interpreter? interpreter;
  final classifier = Classifier();
  final isolateUtils = IsolateUtils();

  bool initialized = false;
  bool isWorking = false;
  DetectionClasses detected = DetectionClasses.nothing;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    // Load main isolate Interpreter
    await classifier.loadModel();
    interpreter = classifier.interpreter;

    final cameras = await availableCameras();
    // Create a CameraController object
    cameraController = CameraController(
      cameras[0], // Choose the first camera in the list
      ResolutionPreset.medium, // Choose a resolution preset
    );

    // Start Inference isolate
    await isolateUtils.start();

    // Initialize the CameraController and start the camera preview
    await cameraController.initialize();
    // Listen for image frames
    await cameraController.startImageStream((image) {
      // Make predictions only if not busy
      if (!isWorking) {
        processCameraImage(image);
      }
    });

    setState(() {
      initialized = true;
    });
  }

  Future<void> processCameraImage(CameraImage cameraImage) async {
    setState(() {
      isWorking = true;
    });

    final result = await inference(cameraImage);

    if (detected != result) {
      setState(() {
        detected = result;
      });
    }

    setState(() {
      isWorking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rice Leaf Disease Detection'),
      ),
      body: initialized
          ? Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: CameraPreview(cameraController),
                ),
                Text(
                  "Detected: ${detected.label}",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.blue,
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Future<DetectionClasses> inference(CameraImage cameraImage) async {
    ReceivePort responsePort = ReceivePort();
    final isolateData = IsolateData(
      cameraImage: cameraImage,
      interpreterAddress: classifier.interpreter.address,
      responsePort: responsePort.sendPort,
    );

    isolateUtils.sendPort.send(isolateData);
    var result = await responsePort.first;

    return result;
  }

  @override
  void dispose() {
    cameraController.dispose();
    isolateUtils.dispose();
    super.dispose();
  }
}
