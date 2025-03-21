import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:currency/color_service.dart';
import 'package:currency/ocr_service.dart';
import 'package:currency/tflite_service.dart';
import 'tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

const Map<String, String> languages = {
  "English": "en-US",
  "Malayalam": "ml-IN",
  "Hindi": "hi-IN",
  "Tamil": "ta-IN",
  "Kannada": "kn-IN",
  "Telugu": "te-IN",
};

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Currency Detector',
      theme: ThemeData.dark(),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  String _result = "";
  String _selectedLanguage = "ml-IN"; // Default to Malayalam

  final TTSService _ttsService = TTSService();
  final TFLiteService _tfliteService = TFLiteService();
  final OCRService _ocrService = OCRService();
  final ColorService _colorService = ColorService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _tfliteService.loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("❌ Camera Initialization Failed: $e");
    }
  }

  bool isValidCurrency(String? text) {
    if (text == null) return false;
    List<String> validDenominations = [
      "10",
      "20",
      "50",
      "100",
      "200",
      "500",
      "2000",
    ];

    // Remove unwanted characters and trim spaces
    String sanitizedText = text.replaceAll(RegExp(r'[^0-9]'), '').trim();

    return validDenominations.contains(sanitizedText);
  }

  Future<void> _captureAndDetect() async {
    if (!_isCameraInitialized || !_tfliteService.isModelLoaded) {
      setState(() => _result = "❌ AI Model Not Loaded!");
      return;
    }

    try {
      final imageFile = await _cameraController.takePicture();
      File image = File(imageFile.path);

      debugPrint("📷 Captured Image: ${image.path}");

      final results = await Future.wait([
        _tfliteService.detectCurrencyWithConfidence(image),
        _ocrService.extractCurrencyText(image),
        _colorService.detectCurrencyColor(image),
      ]);

      var aiResponse = results[0] as Map<String, dynamic>;
      String aiResult = aiResponse['currency'] ?? "";
      double aiConfidence = aiResponse['confidence'] ?? 0.0;

      String? ocrResult = results[1] as String?;
      String? colorResult = results[2] as String?;

      debugPrint(
        "🤖 AI Model Result: $aiResult (Confidence: ${aiConfidence.toStringAsFixed(2)})",
      );
      debugPrint("📝 OCR Result: ${ocrResult ?? "❌ OCR Failed"}");
      debugPrint(
        "🎨 Color Detection Result: ${colorResult ?? "❌ Color Failed"}",
      );

      String? finalResult;

      /// ✅ **1. If AI, OCR, and Color agree, confirm the currency**
      if (isValidCurrency(aiResult) &&
          isValidCurrency(ocrResult) &&
          isValidCurrency(colorResult) &&
          aiResult == ocrResult &&
          ocrResult == colorResult) {
        finalResult = aiResult;
      }
      /// ✅ **2. If AI confidence is high (≥ 0.85) but OCR is different, trust OCR**
      else if (isValidCurrency(ocrResult) && aiConfidence >= 0.85) {
        finalResult = ocrResult;
      }
      /// ✅ **3. If only OCR and Color match, use them**
      else if (isValidCurrency(ocrResult) &&
          isValidCurrency(colorResult) &&
          ocrResult == colorResult) {
        finalResult = ocrResult;
      }
      /// ✅ **4. If only OCR is valid and AI has some result, use OCR**
      else if (isValidCurrency(ocrResult) && isValidCurrency(aiResult)) {
        finalResult = ocrResult;
      }
      /// ❌ **If nothing is valid, reject detection**
      else {
        finalResult = null;
      }

      debugPrint("✅ Currency detected: ${finalResult ?? "None"}");

      if (finalResult != null) {
        print("✅ Confirmed Currency: $finalResult");
        _result = "Detected Currency: $finalResult";
        _ttsService.speak(_result, _selectedLanguage);
      } else {
        print("❌ No currency detected.");
        _result = "❌ No Currency Detected";
        _ttsService.speak(
          "No currency detected. Please try again.",
          _selectedLanguage,
        );
      }

      setState(() {});
    } catch (e) {
      setState(() => _result = "⚠️ Error Capturing Image!");
      debugPrint("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Currency Detector",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language selection dropdown
          DropdownButton<String>(
            value: _selectedLanguage,
            icon: const Icon(Icons.language, color: Colors.white, size: 16),
            dropdownColor: Colors.black,
            underline: SizedBox(), // Remove the underline
            items:
                languages.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.value,
                    child: Row(
                      children: [
                        // Adjust spacing between icon and text
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Added font size
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                });
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                "About Us",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const ListTile(
              title: Text(
                "This app helps in detecting currency using AI and OCR.",
              ),
            ),
            const ListTile(title: Text("Developed By:")),
            const ListTile(title: Text("1. Muhammed Yaseen TH")),
            const ListTile(title: Text("2. Muhammed Aslam KI")),
            const ListTile(title: Text("3. Muhammed Ashik")),
            const ListTile(title: Text("4. Devumol T R")),
            const Divider(),
            const ListTile(title: Text("Project Guide: Miss Shefna Ubais")),
            const Divider(),
            const ListTile(
              title: Text(
                "Ilahia College of Engineering and Technology\nBatch 2022-2026",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController)
              : const Center(child: CircularProgressIndicator()),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: ElevatedButton.icon(
                onPressed: _captureAndDetect,
                icon: const Icon(Icons.camera_alt, size: 84),
                label: const Text(
                  "Scan Currency",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 40,
                  ),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _result.isEmpty ? 0.0 : 1.0,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 800),
                padding: EdgeInsets.only(bottom: _result.isEmpty ? 0 : 100),
                child: Center(
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}
