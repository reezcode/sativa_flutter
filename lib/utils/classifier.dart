import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../core/enums/detection_class.dart';

class Classifier {
  /// Instance of Interpreter
  late Interpreter _interpreter;

  static const String modelFile = "assets/models/rice_model_v4.tflite";

  /// Loads interpreter from asset
  Future<void> loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            modelFile,
            options: InterpreterOptions()..threads = 4,
          );

      _interpreter.allocateTensors();
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  Future<DetectionClasses> predict(img.Image image) async {
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert the resized image to a 1D Float32List.
    Float32List inputBytes = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        int pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = img.getRed(pixel) / 255;
        inputBytes[pixelIndex++] = img.getGreen(pixel) / 255;
        inputBytes[pixelIndex++] = img.getBlue(pixel) / 255;
      }
    }

    final output = Float32List(1 * 4).reshape([1, 4]);

    // Reshape to input format specific for model. 1 item in list with pixels 150x150 and 3 layers for RGB
    final input = inputBytes.reshape([1, 224, 224, 3]);

    interpreter.run(input, output);

    final predictionResult = output[0] as List<double>;
    print(predictionResult);
    double maxElement = predictionResult.reduce(
      (double maxElement, double element) =>
          element > maxElement ? element : maxElement,
    );
    return DetectionClasses.values[predictionResult.indexOf(maxElement)];
  }
}
