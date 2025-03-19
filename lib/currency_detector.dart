// import 'dart:io';
// import 'tflite_service.dart';
// import 'ocr_service.dart';
// import 'color_service.dart';

// class CurrencyDetector {
//   final TFLiteService _tfliteService = TFLiteService();
//   final OCRService _ocrService = OCRService();
//   final ColorService _colorService = ColorService();

//   Future<String> detectCurrency(File image) async {
//     if (!_tfliteService.isModelLoaded) {
//       print("❌ TFLite Model Not Loaded!");
//       return "⚠️ Model not loaded, please wait...";
//     }

//     print("✅ TFLite Model Loaded, starting detection...");

//     // AI Model Detection
//     String? modelResult = await _tfliteService.detectCurrency(image);
//     print("🤖 AI Model Result: $modelResult");

//     // OCR Detection
//     print("Starting OCR process...");
//     String? ocrResult = await _ocrService.extractCurrencyText(image);
//     print("🔍 OCR Raw Result: $ocrResult");

//     // Color Detection
//     print("Starting Color Detection...");
//     String? colorResult = await _colorService.detectCurrencyColor(image);
//     print("🎨 Detected Avg Color: $colorResult");

//     // Decision Logic
//     if (modelResult != null && ocrResult != null && colorResult != null) {
//       return "✅ Confirmed: $modelResult";
//     } else if (ocrResult != null && colorResult != null) {
//       return "✅ Confirmed: $ocrResult";
//     } else if (ocrResult != null) {
//       return "🔠 OCR Detected: $ocrResult";
//     } else {
//       return "❌ No valid currency detected!";
//     }
//   }
// }
