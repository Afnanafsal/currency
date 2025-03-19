import 'dart:io';
import 'package:currency/color_service.dart';
import 'package:currency/ocr_service.dart';
import 'package:currency/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'currency_detector.dart';
import 'tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Advanced Currency Detector',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(cameras: cameras),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  HomeScreen({super.key, required this.cameras});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  String _result = "Place currency inside the box";
  // final CurrencyDetector _currencyDetector = CurrencyDetector();
  final TTSService _ttsService = TTSService();
  final TFLiteService _tfliteService = TFLiteService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _tfliteService.loadModel();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureAndDetect() async {
    if (!_isCameraInitialized || !_tfliteService.isModelLoaded) {
      setState(() => _result = "❌ AI Model Not Loaded!");
      return;
    }

    try {
      final imageFile = await _cameraController.takePicture();
      File image = File(imageFile.path);

      print("📷 Captured Image: ${image.path}");

      // Step 1: Check with AI Model
      print("🤖 Running AI Model...");
      String aiResult = await _tfliteService.detectCurrency(image);
      print("🔍 AI Model Result: $aiResult");

      // Step 2: Check with OCR
      print("📝 Running OCR...");
      String? ocrResult = await OCRService().extractCurrencyText(image);
      print("📝 OCR Result: $ocrResult");

      // Step 3: Check with Color Detection
      print("🎨 Running Color Detection...");
      String? colorResult = await ColorService().detectCurrencyColor(image);
      print("🎨 Color Detection Result: $colorResult");

      // Step 4: Final Decision Logic
      if (aiResult == ocrResult &&
          aiResult == colorResult &&
          aiResult != null) {
        _result = "✅ Confirmed by AI, OCR & Color: $aiResult";
      } else if (ocrResult == colorResult && ocrResult != null) {
        _result = "✅ Confirmed by OCR & Color: $ocrResult";
      } else if (ocrResult != null) {
        _result = "🔠 OCR Suggests: $ocrResult";
      } else if (colorResult != null) {
        _result = "🎨 Color Suggests: $colorResult";
      } else {
        _result = "❌ No Reliable Match!";
      }

      setState(() {});
      _ttsService.speak(_result);
    } catch (e) {
      setState(() => _result = "⚠️ Error Capturing Image!");
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Currency Detector"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController)
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 30,
            right: 30,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _captureAndDetect,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Currency"),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
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
