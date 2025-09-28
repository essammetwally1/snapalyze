// lib/services/analysis_service.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class AnalysisService {
  static Future<Map<String, dynamic>> analyzeImage(File image) async {
    try {
      final stat = await image.stat();
      final bytes = await image.readAsBytes();

      // Get dimensions fast
      final size = await _readDimensions(bytes);
      final mp = (size.width * size.height) / 1e6;

      // Decode small thumbnail for metrics
      final thumb = await _decodeThumbnail(bytes, maxSide: 256);
      final bd = await thumb.toByteData(format: ui.ImageByteFormat.rawRgba);
      thumb.dispose();
      if (bd == null) throw StateError('Could not read pixel data.');

      final rgba = bd.buffer.asUint8List();

      final brightness = _avgLuma(rgba);
      final contrast = _contrastApprox(rgba, brightness);
      final sharpness = _laplacianVariance(
        rgba,
        thumbWidth: 256,
        thumbHeight: 256,
      );
      final colors = _dominantColors(rgba, maxColors: 5);
      final colorProfile = _heuristicColorProfile(bytes);
      final detail = _estimateObjects(size);
      final quality = _assessQuality(stat.size, size);

      return {
        'analysis': {
          'fileSize': _formatBytes(stat.size),
          'dimensions': '${size.width.toInt()}x${size.height.toInt()}',
          'aspectRatio': (size.width / size.height).toStringAsFixed(2),
          'megapixels': mp.toStringAsFixed(2),
          'estimatedObjects': detail,
          'imageQuality': quality,
          'colorProfile': colorProfile,
          'brightness01': double.parse(brightness.toStringAsFixed(3)),
          'contrast01': double.parse(contrast.toStringAsFixed(3)),
          'sharpness01': double.parse(sharpness.toStringAsFixed(3)),
          'dominantColorsARGB': colors
              .map((e) => '0x${e.toRadixString(16).padLeft(8, '0')}')
              .toList(),
        },
        'suggestions': _generateSuggestions(
          dims: size,
          fileSize: stat.size,
          brightness: brightness,
          contrast: contrast,
          sharpness: sharpness,
          megapixels: mp,
        ),
      };
    } catch (e) {
      // Keep the same shape so UI doesn’t break
      return {
        'analysis': {
          'file Size': 'Unknown',
          'dimensions': 'Unknown',
          'aspect Ratio': 'Unknown',
          'megapixels': 'Unknown',
          'estimated Objects': 'Unknown',
          'image Quality': 'Unknown',
          'color Profile': 'Unknown',
          'brightness01': 0.0,
          'contrast01': 0.0,
          'sharpness01': 0.0,
          'dominant Colors ARGB': <String>[],
        },
        'suggestions': ['Analysis failed: $e'],
      };
    }
  }

  // ---------- Efficient decoding / metadata ----------

  static Future<ui.Size> _readDimensions(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final w = desc.width.toDouble();
      final h = desc.height.toDouble();
      desc.dispose();
      return ui.Size(w, h);
    } finally {
      buffer.dispose();
    }
  }

  static Future<ui.Image> _decodeThumbnail(
    Uint8List bytes, {
    required int maxSide,
  }) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: maxSide,
      targetHeight: maxSide,
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  // ---------- Heuristics / metrics ----------

  static String _heuristicColorProfile(Uint8List bytes) {
    // No ICC/EXIF parsing here; assume sRGB for app-friendly default
    return bytes.length > 8 * 1024 * 1024
        ? 'Likely sRGB / Display P3'
        : 'sRGB (assumed)';
  }

  static String _estimateObjects(ui.Size size) {
    final pixels = size.width * size.height;
    if (pixels > 4e6) return 'High Detail (multiple objects detectable)';
    if (pixels > 1e6) return 'Medium Detail (main objects detectable)';
    return 'Basic Detail (limited analysis)';
  }

  static String _assessQuality(int fileSize, ui.Size dimensions) {
    final mp = (dimensions.width * dimensions.height) / 1e6;
    if (mp > 8 && fileSize > 2 * 1024 * 1024) return 'Excellent';
    if (mp > 4 && fileSize > 1 * 1024 * 1024) return 'Good';
    return 'Basic';
  }

  // Average perceived luminance (0..1)
  static double _avgLuma(Uint8List rgba) {
    double sum = 0;
    final len = rgba.lengthInBytes;
    for (int i = 0; i < len; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      sum += 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }
    return (sum / (rgba.lengthInBytes / 4)) / 255.0;
  }

  // Simple contrast proxy: normalized std-dev of luma
  // Fix the contrast method
  static double _contrastApprox(Uint8List rgba, double meanLuma01) {
    double variance = 0;
    final pixelCount = rgba.lengthInBytes ~/ 4;
    if (pixelCount == 0) return 0.0;

    for (int i = 0; i < rgba.lengthInBytes; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
      final d = y - meanLuma01;
      variance += d * d;
    }
    final std = math.sqrt(variance / pixelCount);
    return std.clamp(0.0, 1.0).toDouble(); // FIX: Add .toDouble()
  }

  // Sharpness proxy: variance of Laplacian (grayscale), normalized
  static double _laplacianVariance(
    Uint8List rgba, {
    required int thumbWidth,
    required int thumbHeight,
  }) {
    final w = thumbWidth;
    final h = thumbHeight;

    final gray = Float32List(w * h);
    int gi = 0;
    for (int i = 0; i < rgba.lengthInBytes; i += 4) {
      final r = rgba[i].toDouble();
      final g = rgba[i + 1].toDouble();
      final b = rgba[i + 2].toDouble();
      gray[gi++] = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    double sum = 0, sumSq = 0;
    for (int y = 1; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        final c =
            gray[y * w + x] * -4.0 +
            gray[y * w + (x - 1)] +
            gray[y * w + (x + 1)] +
            gray[(y - 1) * w + x] +
            gray[(y + 1) * w + x];
        sum += c;
        sumSq += c * c;
      }
    }
    final n = (w - 2) * (h - 2);
    final mean = sum / n;
    final variance = (sumSq / n) - (mean * mean);

    final normalized = (variance / 20000.0);
    return normalized.clamp(0.0, 1.0);
  }

  // Coarse dominant colors via histogram binning (ARGB ints)
  static List<int> _dominantColors(Uint8List rgba, {int maxColors = 5}) {
    const binsPer = 8; // 8*8*8 = 512
    final counts = <int, int>{};

    for (int i = 0; i < rgba.lengthInBytes; i += 4) {
      final r = rgba[i] >> (8 - 3);
      final g = rgba[i + 1] >> (8 - 3);
      final b = rgba[i + 2] >> (8 - 3);
      final key = (r << 6) | (g << 3) | b;
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final out = <int>[];
    for (final e in sorted.take(maxColors)) {
      final r = ((e.key >> 6) & 0x7) * 255 ~/ (binsPer - 1);
      final g = ((e.key >> 3) & 0x7) * 255 ~/ (binsPer - 1);
      final b = (e.key & 0x7) * 255 ~/ (binsPer - 1);
      out.add(0xFF000000 | (r << 16) | (g << 8) | b);
    }
    return out;
  }

  // ---------- Suggestions ----------

  static List<String> _generateSuggestions({
    required ui.Size dims,
    required int fileSize,
    required double brightness,
    required double contrast,
    required double sharpness,
    required double megapixels,
  }) {
    final s = <String>[];

    if (dims.width * dims.height < 0.5e6) {
      s.add('Use a higher resolution image (≥ 1MP) for better analysis.');
    }
    if (fileSize > 5 * 1024 * 1024) {
      s.add('Large file size may slow down processing; consider compressing.');
    }
    if (brightness < 0.25) s.add('Underexposed—add light or raise exposure.');
    if (brightness > 0.85) s.add('Overexposed—lower exposure or use HDR.');
    if (contrast < 0.12) s.add('Low contrast—adjust curves/levels.');
    if (sharpness < 0.15) s.add('Soft focus—use tripod/AF or faster shutter.');
    if (megapixels >= 8 && sharpness >= 0.4) {
      s.add('Good for object detection and cropping.');
    }
    return s;
  }

  // ---------- Utils ----------

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double v = bytes.toDouble();
    int u = 0;
    while (v >= 1024 && u < units.length - 1) {
      v /= 1024;
      u++;
    }
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[u]}';
  }
}
