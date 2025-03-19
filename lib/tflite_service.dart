import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;
  final FlutterTts _flutterTts = FlutterTts();
  bool isModelLoaded = false;

  // Labels for AI classification
  final List<String> currencyLabels = ["₹20", "₹500", "₹200", "₹100", "₹10"];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/model.tflite");
      isModelLoaded = true;
      print("✅ TFLite Model Successfully Loaded!");
    } catch (e) {
      print("❌ Error Loading TFLite Model: $e");
      isModelLoaded = false;
    }
  }

  /// **Detect currency using AI model only**
  Future<String> detectCurrency(File image) async {
    if (!isModelLoaded) {
      return "Error: Model not loaded";
    }

    try {
      // Try AI Model
      String? detectedCurrency = await _detectCurrencyWithModel(image);
      if (detectedCurrency != null) {
        await _speak("Detected currency is $detectedCurrency");
        return "Detected Currency: $detectedCurrency";
      }

      return "No currency detected";
    } catch (e) {
      return "Error detecting currency: $e";
    }
  }

  /// **AI Model Detection**
  Future<String?> _detectCurrencyWithModel(File image) async {
    try {
      img.Image? decodedImage = img.decodeImage(image.readAsBytesSync());
      if (decodedImage == null) return null;

      img.Image resizedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );
      List<List<List<List<double>>>> input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(224, (x) {
            var pixel = resizedImage.getPixel(x, y);
            return [
              (pixel.r - 128) / 128.0,
              (pixel.g - 128) / 128.0,
              (pixel.b - 128) / 128.0,
            ];
          }),
        ),
      );

      List<List<double>> output = [List.filled(currencyLabels.length, 0.0)];
      _interpreter.run(input, output);

      double maxConfidence = output[0].reduce((a, b) => a > b ? a : b);
      int predictedIndex = output[0].indexOf(maxConfidence);

      if (maxConfidence >= 0.7) {
        return currencyLabels[predictedIndex];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void close() {
    _interpreter.close();
  }
}
