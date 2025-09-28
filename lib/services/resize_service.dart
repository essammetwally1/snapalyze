import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'; // compute
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ResizeOutput {
  final File file;
  final int width;
  final int height;

  ResizeOutput({required this.file, required this.width, required this.height});
}

// Quality levels for smooth resizing
enum ResizeQuality {
  fast(img.Interpolation.average),
  balanced(img.Interpolation.linear),
  smooth(img.Interpolation.cubic);

  const ResizeQuality(this.interpolation);
  final img.Interpolation interpolation;
}

class ResizeService {
  static const _maxDimension = 8192;

  /// Resize by explicit width & height (px) - FORCES exact dimensions
  Future<ResizeOutput> resize({
    required String path,
    required int width,
    required int height,
    int jpegQuality = 90,
    bool preventUpscale = true,
    bool maintainAspectRatio = false, // NEW: Option to maintain proportions
    ResizeQuality quality = ResizeQuality.balanced,
  }) async {
    _validateInputDimensions(width, height);

    final res = await compute<_ResizeArgs, _ResizeResult>(
      _resizeIsolate,
      _ResizeArgs(
        path: path,
        width: width,
        height: height,
        jpegQuality: jpegQuality,
        preventUpscale: preventUpscale,
        maintainAspectRatio: maintainAspectRatio,
        interpolation: quality.interpolation,
      ),
    );

    final outFile = await _writeTempJpeg(res.bytes);
    return ResizeOutput(file: outFile, width: res.width, height: res.height);
  }

  /// Resize by aspect ratio - SMOOTH resize maintaining proportions
  Future<ResizeOutput> resizeByAspect({
    required String path,
    required int aspectW,
    required int aspectH,
    required int target,
    required bool targetIsWidth,
    int jpegQuality = 90,
    bool preventUpscale = true,
    ResizeQuality quality =
        ResizeQuality.smooth, // Default to smooth for aspect ratio
  }) async {
    assert(aspectW > 0 && aspectH > 0 && target > 0);
    _validateInputDimension(target);

    // Get original image dimensions to calculate accurate aspect ratio
    final originalImage = img.decodeImage(await File(path).readAsBytes());
    if (originalImage == null) {
      throw Exception('Unable to decode image.');
    }

    final double targetRatio = aspectW / aspectH;
    final double originalRatio = originalImage.width / originalImage.height;

    int outW, outH;

    if (targetIsWidth) {
      outW = target;
      outH = (target / targetRatio).round();
    } else {
      outH = target;
      outW = (target * targetRatio).round();
    }

    // Apply upscale prevention
    if (preventUpscale) {
      outW = math.min(outW, originalImage.width);
      outH = math.min(outH, originalImage.height);

      // Recalculate to maintain aspect ratio after upscale prevention
      if (targetIsWidth) {
        outH = (outW / targetRatio).round();
      } else {
        outW = (outH * targetRatio).round();
      }
    }

    _validateOutputDimensions(outW, outH);

    return resize(
      path: path,
      width: outW,
      height: outH,
      jpegQuality: jpegQuality,
      preventUpscale: preventUpscale,
      maintainAspectRatio:
          false, // Already calculated exact aspect ratio dimensions
      quality: quality,
    );
  }

  // ---- Validation helpers ----
  void _validateInputDimension(int dimension) {
    if (dimension <= 0) {
      throw Exception('Dimension must be greater than 0');
    }
    if (dimension > _maxDimension) {
      throw Exception('Dimension cannot exceed $_maxDimension pixels');
    }
  }

  void _validateInputDimensions(int width, int height) {
    _validateInputDimension(width);
    _validateInputDimension(height);
    if (width * height > _maxDimension * _maxDimension) {
      throw Exception('Total pixel count exceeds maximum allowed');
    }
  }

  void _validateOutputDimensions(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw Exception('Calculated dimensions are invalid: ${width}x$height');
    }
    if (width > _maxDimension || height > _maxDimension) {
      throw Exception(
        'Calculated dimensions too large: ${width}x$height (max: $_maxDimension)',
      );
    }
  }

  // ---- File helpers ----
  Future<File> _writeTempJpeg(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final p =
        '${dir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final f = File(p);
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  // Cleanup temporary files
  Future<void> cleanupTempFiles({int daysOld = 1}) async {
    try {
      final dir = await getTemporaryDirectory();
      final files = dir.listSync();
      final cutoff = DateTime.now().subtract(Duration(days: daysOld));

      for (final file in files) {
        if (file is File &&
            file.path.contains('resized_') &&
            file.statSync().modified.isBefore(cutoff)) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silent cleanup failure
      if (kDebugMode) {
        print('Cleanup failed: $e');
      }
    }
  }
}

// ===== Isolate work =====

class _ResizeArgs {
  final String path;
  final int width;
  final int height;
  final int jpegQuality;
  final bool preventUpscale;
  final bool maintainAspectRatio;
  final img.Interpolation interpolation;

  _ResizeArgs({
    required this.path,
    required this.width,
    required this.height,
    required this.jpegQuality,
    required this.preventUpscale,
    required this.maintainAspectRatio,
    required this.interpolation,
  });
}

class _ResizeResult {
  final List<int> bytes;
  final int width;
  final int height;

  _ResizeResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

_ResizeResult _resizeIsolate(_ResizeArgs a) {
  try {
    final bytes = File(a.path).readAsBytesSync();
    if (bytes.isEmpty) {
      throw Exception('Empty file');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format or corrupted file');
    }

    int w = a.width;
    int h = a.height;

    // Maintain aspect ratio if requested
    if (a.maintainAspectRatio) {
      final originalRatio = decoded.width / decoded.height;
      final targetRatio = w / h;

      if (targetRatio > originalRatio) {
        // Width is the constraining dimension - adjust height
        h = (w / originalRatio).round();
      } else {
        // Height is the constraining dimension - adjust width
        w = (h * originalRatio).round();
      }
    }

    // Apply upscale prevention
    if (a.preventUpscale) {
      w = math.min(w, decoded.width);
      h = math.min(h, decoded.height);
    }

    // Ensure minimum dimensions
    w = math.max(1, w);
    h = math.max(1, h);

    // Perform the resize with specified interpolation
    final resized = img.copyResize(
      decoded,
      width: w,
      height: h,
      interpolation: a.interpolation,
    );

    // Encode to JPEG with quality control
    final out = img.encodeJpg(resized, quality: a.jpegQuality.clamp(1, 100));

    return _ResizeResult(
      bytes: out,
      width: resized.width,
      height: resized.height,
    );
  } catch (e) {
    throw Exception('Image resize failed: ${e.toString()}');
  }
}
