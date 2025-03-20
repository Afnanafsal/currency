import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

class TFLiteService {
  late Interpreter _interpreter;
  final FlutterTts _flutterTts = FlutterTts();
  bool isModelLoaded = false;

  TFLiteService() {
    loadModel();
  }
  // Labels for AI classification
  final List<String> currencyLabels = ["₹20", "₹500", "₹200", "₹100", "₹10"];

  Future<void> loadModel() async {
    try {
      var options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        "assets/model.tflite",
        options: options,
      );
      isModelLoaded = true;
      print("✅ TFLite Model Successfully Loaded with 4 threads!");
    } catch (e) {
      print("❌ Error Loading TFLite Model: $e");
      isModelLoaded = false;
    }
  }

  Future<String> detectCurrency(File image) async {
    if (!isModelLoaded) {
      return "Error: Model not loaded";
    }

    try {
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

      // Flatten image pixels to match the model input shape
      List<double> input = [];
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          var pixel = resizedImage.getPixel(x, y);
          input.add((pixel.r - 128) / 128.0);
          input.add((pixel.g - 128) / 128.0);
          input.add((pixel.b - 128) / 128.0);
        }
      }

      // Convert input into Float32 format
      var inputBuffer = Float32List.fromList(input).reshape([1, 224, 224, 3]);

      List<List<double>> output = [List.filled(currencyLabels.length, 0.0)];
      _interpreter.run(inputBuffer, output);

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

  Future<img.Image?> _processImage(File image) async {
    try {
      return await compute(_decodeImage, image.readAsBytesSync());
    } catch (e) {
      print("❌ Image Processing Error: $e");
      return null;
    }
  }

  // This function runs in the background
  img.Image? _decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// **Detect currency with confidence score**
  Future<Map<String, dynamic>> detectCurrencyWithConfidence(File image) async {
    if (!isModelLoaded) {
      print("⚠️ Model Not Loaded!");
      return {"currency": "Unknown", "confidence": 0.0};
    }

    try {
      img.Image? decodedImage = await _processImage(image);
      if (decodedImage == null)
        return {"currency": "Unknown", "confidence": 0.0};

      img.Image resizedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );

      // Flatten image pixels to match the model input shape
      List<double> input = [];
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          var pixel = resizedImage.getPixel(x, y);
          input.add((pixel.r - 128) / 128.0);
          input.add((pixel.g - 128) / 128.0);
          input.add((pixel.b - 128) / 128.0);
        }
      }

      // Convert input into Float32 format
      var inputBuffer = Float32List.fromList(input).reshape([1, 224, 224, 3]);

      List<List<double>> output = [List.filled(currencyLabels.length, 0.0)];
      _interpreter.run(inputBuffer, output);

      double maxConfidence = output[0].reduce((a, b) => a > b ? a : b);
      int predictedIndex = output[0].indexOf(maxConfidence);

      if (maxConfidence >= 0.5) {
        String detectedCurrency = currencyLabels[predictedIndex];
        print(
          "📌 Detected: $detectedCurrency (Confidence: ${maxConfidence.toStringAsFixed(2)})",
        );

        await _speak("Detected currency is $detectedCurrency");

        return {"currency": detectedCurrency, "confidence": maxConfidence};
      } else {
        return {"currency": "Unknown", "confidence": maxConfidence};
      }
    } catch (e) {
      print("❌ Error in AI Detection: $e");
      return {"currency": "Unknown", "confidence": 0.0};
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void close() {
    _interpreter.close();
  }
}
