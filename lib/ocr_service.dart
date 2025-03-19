import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String?> extractCurrencyText(File image) async {
    print("Starting OCR process...");

    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    print("OCR raw result: ${recognizedText.text}");

    List<String> currencyPatterns = [
      "10",
      "20",
      "50",
      "100",
      "200",
      "500",
      "2000",
    ];

    for (TextBlock block in recognizedText.blocks) {
      String blockText = block.text.replaceAll(
        RegExp(r'\s+'),
        '',
      ); // Remove spaces
      print("Checking block: $blockText");

      // Extract only numbers from the detected text
      String? extractedNumber = _extractNumber(blockText);

      if (extractedNumber != null &&
          currencyPatterns.contains(extractedNumber)) {
        print("✅ Currency detected: ₹$extractedNumber");
        return "₹$extractedNumber";
      }
    }

    print("❌ No currency detected.");
    return null;
  }

  String? _extractNumber(String text) {
    // Use RegExp to extract only the first numeric sequence
    RegExp regex = RegExp(r'\d+');
    Match? match = regex.firstMatch(text);
    return match?.group(0); // Returns only the number
  }

  void dispose() {
    _textRecognizer.close();
  }
}
