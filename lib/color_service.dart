import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:image/image.dart' as img;

class ColorService {
  final Map<String, List<List<int>>> currencyColors = {
    "₹10": [
      [255, 153, 51], // Orange
      [214, 138, 89], // Dark Brown
    ],
    "₹20": [
      [224, 187, 106], // Yellow-Brown
      [201, 165, 111], // Light Brown
    ],
"₹50": [
  [119, 187, 218], // Sky Blue
  [95, 155, 202],  // Medium Blue
  [56, 116, 162],  // Deep Blue
],

    "₹100": [
      [170, 219, 220],
      [142, 163, 193], // Violet-Blue
      [79, 139, 183], // Blue
      [113, 69, 142], // Deep Purple (Added)
    ],
    "₹200": [
      [230, 148, 59], // Orange-Brown
    ],
    "₹500": [
      [134, 138, 131], // Stone Grey
      [157, 160, 151], // Light Grey
    ],
    "₹2000": [
      [157, 105, 172], // Magenta
    ],
    
  };

  Future<String?> detectCurrencyColor(File image) async {
    try {
      img.Image? decodedImage = img.decodeImage(image.readAsBytesSync());
      if (decodedImage == null) return null;

      List<int> avgColor = _getFilteredAverageColor(decodedImage);

      debugPrint(
        "🎨 Detected Avg Color: R${avgColor[0]}, G${avgColor[1]}, B${avgColor[2]}",
      );

      String? bestMatch;
      List<int>? matchedColor;
      int lowestDifference = 255 * 3; // Max possible difference
      String debugInfo = "🎨 Color Differences:\n";

      for (var entry in currencyColors.entries) {
        for (var refColor in entry.value) {
          int difference = _colorDifference(avgColor, refColor);
          debugInfo +=
              "  🔹 ${entry.key}: Diff $difference (Color: R${refColor[0]}, G${refColor[1]}, B${refColor[2]})\n";

          if (difference < lowestDifference) {
            lowestDifference = difference;
            bestMatch = entry.key;
            matchedColor = refColor;
          }
        }
      }

      debugPrint(debugInfo); // Log all differences

      if (bestMatch != null && matchedColor != null && lowestDifference < 40) {
        // Stricter threshold
        debugPrint(
          "✅ Matched with $bestMatch (Diff: $lowestDifference) using color R${matchedColor[0]}, G${matchedColor[1]}, B${matchedColor[2]}",
        );
        return "$bestMatch";
      }

      debugPrint("❌ No Reliable Color Match Found");
      return null;
    } catch (e) {
      debugPrint("❌ Error in Color Detection: $e");
      return null;
    }
  }

  List<int> _getFilteredAverageColor(img.Image image) {
    int centerX = image.width ~/ 2;
    int centerY = image.height ~/ 2;
    int sampleSize = 120; // Sampling area size

    int red = 0, green = 0, blue = 0, count = 0;

    List<List<int>> sampleRegions = [
      [centerX, centerY], // Center
      [centerX - sampleSize ~/ 3, centerY], // Left
      [centerX + sampleSize ~/ 3, centerY], // Right
      [centerX, centerY - sampleSize ~/ 3], // Top
      [centerX, centerY + sampleSize ~/ 3], // Bottom
    ];

    for (var region in sampleRegions) {
      int xStart = region[0] - sampleSize ~/ 6;
      int yStart = region[1] - sampleSize ~/ 6;

      for (int x = xStart; x < xStart + sampleSize ~/ 3; x++) {
        for (int y = yStart; y < yStart + sampleSize ~/ 3; y++) {
          if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;

          img.Pixel pixel = image.getPixel(x, y);
          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();

          if (_isMarked(r, g, b)) continue; // Skip known marker colors

          red += r;
          green += g;
          blue += b;
          count++;
        }
      }
    }

    if (count > 0) {
      red ~/= count;
      green ~/= count;
      blue ~/= count;
    }

    debugPrint("🎨 Adjusted Avg Color: R$red, G$green, B$blue");
    return [red, green, blue];
  }

  int _colorDifference(List<int> detected, List<int> reference) {
    return (detected[0] - reference[0]).abs() +
        (detected[1] - reference[1]).abs() +
        (detected[2] - reference[2]).abs();
  }

  bool _isMarked(int r, int g, int b) {
    return (r < 50 && g < 50 && b < 50) || // Black marker
        (r > 150 && g < 50 && b < 50); // Red marker
  }
}
