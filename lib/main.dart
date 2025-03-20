import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:currency/color_service.dart';
import 'package:currency/ocr_service.dart';
import 'package:currency/tflite_service.dart';
import 'package:currency/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SplashScreen({super.key, required this.cameras});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(cameras: widget.cameras),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 150), // Your app logo
            const SizedBox(height: 20),
            const Text(
              "Advanced Currency Detector",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Main App
class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Currency Detector',
      theme: ThemeData.dark(),
      home: SplashScreen(cameras: cameras),
    );
  }
}

// Home Screen
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

  Future<void> _captureAndDetect() async {
    if (!_isCameraInitialized || !_tfliteService.isModelLoaded) {
      setState(() => _result = "❌ AI Model Not Loaded!");
      return;
    }

    try {
      final imageFile = await _cameraController.takePicture();
      File image = File(imageFile.path);

      debugPrint("📷 Captured Image: ${image.path}");

      // Run AI, OCR, and Color Detection
      final results = await Future.wait([
        _tfliteService.detectCurrencyWithConfidence(image),
        _ocrService.extractCurrencyText(image),
        _colorService.detectCurrencyColor(image),
      ]);

      // Extract results
      var aiResponse = results[0] as Map<String, dynamic>;
      String aiResult = aiResponse['currency'] ?? "";
      double aiConfidence = aiResponse['confidence'] ?? 0.0;

      String? ocrResult = results[1] as String?;
      String? colorResult = results[2] as String?;

      // Determine final result
      String finalResult = "";

      if (ocrResult == colorResult && ocrResult != null) {
        finalResult = ocrResult;
      } else if (aiConfidence > 0.75 &&
          aiResult == ocrResult &&
          aiResult == colorResult) {
        finalResult = aiResult;
      } else if (ocrResult != null) {
        finalResult = ocrResult;
      } else if (colorResult != null) {
        finalResult = colorResult;
      }

      // Display result
      if (finalResult.isNotEmpty) {
        _result = "Detected Currency: $finalResult";
        _ttsService.speak(_result);
      } else {
        _result = "❌ No Currency Detected";
        _ttsService.speak("No currency detected. Please try again.");
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
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                "About Us",
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
              child: const Center(
                child: Text(
                  "Align currency inside the box",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton.icon(
              onPressed: _captureAndDetect,
              icon: const Icon(Icons.camera_alt, size: 40),
              label: const Text(
                "Scan Currency",
                style: TextStyle(fontSize: 24),
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
