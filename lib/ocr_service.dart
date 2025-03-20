import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Uint8List preprocessImage(Uint8List imageData) {
    img.Image? image = img.decodeImage(imageData);
    if (image == null) return imageData; // Return original if decode fails
    return Uint8List.fromList(img.encodeJpg(img.grayscale(image)));
  }

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

  Future<String> runOCR(XFile imageFile) async {
    final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
    final TextRecognizer textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String ocrText = recognizedText.text;
    textRecognizer.close();

    // Use regex to extract ₹ and number
    RegExp regex = RegExp(r'₹?\s?(\d+)');
    Match? match = regex.firstMatch(ocrText);

    if (match != null) {
      return "₹${match.group(1)}"; // Extract the valid denomination
    }
    return "OCR Failed";
  }

  void dispose() {
    _textRecognizer.close();
  }
}
