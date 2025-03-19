import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:image/image.dart' as img;

class ColorService {
  final Map<String, List<int>> currencyColors = {
    "₹10 (New)": [255, 153, 51], // Orange
    "₹10 (Old)": [214, 138, 89], // Dark Brown
    "₹20 (New)": [224, 187, 106], // Yellow-Brown
    "₹20 (Old)": [201, 165, 111], // Light Brown
    "₹50 (New)": [170, 219, 220], // Fluorescent Blue
    "₹50 (Old)": [142, 163, 193], // Violet-Blue
    "₹100 (New)": [79, 139, 183], // Blue
    "₹100 (Old)": [113, 69, 142], // Deep Purple
    "₹200 (New)": [230, 148, 59], // Orange-Brown
    "₹500 (New)": [134, 138, 131], // Stone Grey
    "₹500 (Old)": [157, 160, 151], // Light Grey
    "₹2000 (New)": [157, 105, 172], // Magenta
    "₹1000 (Old)": [186, 138, 106], // Brownish-Red (Discontinued)
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
      int lowestDifference = 255 * 3;

      for (var entry in currencyColors.entries) {
        int difference = _colorDifference(avgColor, entry.value);
        if (difference < lowestDifference) {
          lowestDifference = difference;
          bestMatch = entry.key;
        }
      }

      if (bestMatch != null && lowestDifference < 50) {
        debugPrint("✅ Matched with $bestMatch (Diff: $lowestDifference)");
        return bestMatch;
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
    int sampleSize = 50;

    int red = 0, green = 0, blue = 0, count = 0;

    for (
      int x = centerX - sampleSize ~/ 2;
      x < centerX + sampleSize ~/ 2;
      x++
    ) {
      for (
        int y = centerY - sampleSize ~/ 2;
        y < centerY + sampleSize ~/ 2;
        y++
      ) {
        img.Pixel pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        if (_isMarked(r, g, b)) continue; // Skip markers

        red += r;
        green += g;
        blue += b;
        count++;
      }
    }

    return count > 0
        ? _normalizeColor([red ~/ count, green ~/ count, blue ~/ count])
        : [0, 0, 0];
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

  List<int> _normalizeColor(List<int> color) {
    int sum = color.reduce((a, b) => a + b);
    return sum > 0
        ? color.map((c) => ((c / sum) * 255).toInt()).toList()
        : color;
  }
}
