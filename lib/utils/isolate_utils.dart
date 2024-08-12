import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:sativa_flutter/core/enums/detection_class.dart';
import 'package:sativa_flutter/utils/classifier.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_utils.dart';

class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  SendPort responsePort;

  IsolateData({
    required this.cameraImage,
    required this.interpreterAddress,
    required this.responsePort,
  });
}

class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  late Isolate _isolate;
  final ReceivePort _receivePort = ReceivePort();
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: DEBUG_NAME,
    );

    _sendPort = await _receivePort.first;
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final IsolateData isolateData in port) {
      Classifier classifier = Classifier();
      // Restore interpreter from main isolate
      await classifier.loadModel(
          interpreter: Interpreter.fromAddress(isolateData.interpreterAddress));

      final convertedImage =
          ImageUtils.convertYUV420ToImage(isolateData.cameraImage);
      DetectionClasses results = await classifier.predict(convertedImage);
      isolateData.responsePort.send(results);
    }
  }

  void dispose() {
    _isolate.kill();
  }
}
