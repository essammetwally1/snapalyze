// lib/services/resize_service.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'; // compute, kDebugMode
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ResizeOutput {
  final File file;
  final int width;
  final int height;

  ResizeOutput({required this.file, required this.width, required this.height});
}

// Quality levels for smoothing
enum ResizeQuality {
  fast(img.Interpolation.average),
  balanced(img.Interpolation.linear),
  smooth(img.Interpolation.cubic);

  const ResizeQuality(this.interpolation);
  final img.Interpolation interpolation;
}

/// Ratio enforcement mode
enum AspectMode {
  /// Crop overflow to fill the ratio (no letterboxing)
  fillCrop,

  /// Pad/letterbox to fit inside the ratio (no cropping)
  fitPad,
}

class ResizeService {
  static const _maxDimension = 8192;

  /// Resize by explicit width & height (px).
  /// If [maintainAspectRatio] is false, this will stretch to the exact size.
  Future<ResizeOutput> resize({
    required String path,
    required int width,
    required int height,
    int jpegQuality = 90,
    bool preventUpscale = true,
    bool maintainAspectRatio = false,
    bool forceJpeg = false, // if true, always JPEG (drops alpha)
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
        aspectPayload: null,
        forceJpeg: forceJpeg,
      ),
    );

    final outFile = await _writeTempImage(res.bytes, res.ext);
    return ResizeOutput(file: outFile, width: res.width, height: res.height);
  }

  /// Resize by aspect ratio WITHOUT distortion.
  ///
  /// - If [targetIsWidth] is true, the **output width is exactly [target]** and
  ///   the height is computed from the ratio (and vice-versa if false).
  /// - [mode] chooses how to enforce the ratio: crop (fill) or pad (fit).
  /// - If [forcePrimaryExact] is true (default), the primary dimension is exact
  ///   even if it requires upscaling (overrides [preventUpscale] for that axis).
  Future<ResizeOutput> resizeByAspect({
    required String path,
    required int aspectW,
    required int aspectH,
    required int target,
    required bool targetIsWidth,
    AspectMode mode = AspectMode.fillCrop,
    int? padColorArgb, // only used when mode == fitPad; e.g. 0xFFFFFFFF = white
    bool forcePrimaryExact = true,
    int jpegQuality = 90,
    bool preventUpscale = true,
    bool forceJpeg = false,
    ResizeQuality quality = ResizeQuality.smooth,
  }) async {
    assert(aspectW > 0 && aspectH > 0 && target > 0);
    _validateInputDimension(target);

    final res = await compute<_ResizeArgs, _ResizeResult>(
      _resizeIsolate,
      _ResizeArgs(
        path: path,
        width: targetIsWidth ? target : -1,
        height: targetIsWidth ? -1 : target,
        jpegQuality: jpegQuality,
        preventUpscale: preventUpscale,
        maintainAspectRatio: true, // always true for AR path (no distortion)
        interpolation: quality.interpolation,
        aspectPayload: _AspectPayload(
          aspectW: aspectW,
          aspectH: aspectH,
          targetIsWidth: targetIsWidth,
          mode: mode,
          padColorArgb: padColorArgb,
          forcePrimaryExact: forcePrimaryExact,
        ),
        forceJpeg: forceJpeg,
      ),
    );

    final outFile = await _writeTempImage(res.bytes, res.ext);
    return ResizeOutput(file: outFile, width: res.width, height: res.height);
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

  // ---- File helper ----
  Future<File> _writeTempImage(List<int> bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final p =
        '${dir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final f = File(p);
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  // Optional: cleanup temporary files
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
      if (kDebugMode) {
        // ignore: avoid_print
        print('Cleanup failed: $e');
      }
    }
  }
}

// ===== Isolate plumbing =====

class _AspectPayload {
  final int aspectW;
  final int aspectH;
  final bool targetIsWidth;
  final AspectMode mode;
  final int? padColorArgb;
  final bool forcePrimaryExact;

  _AspectPayload({
    required this.aspectW,
    required this.aspectH,
    required this.targetIsWidth,
    required this.mode,
    required this.padColorArgb,
    required this.forcePrimaryExact,
  });
}

class _ResizeArgs {
  final String path;
  final int width; // in AR mode, -1 means "compute from height & ratio"
  final int height; // in AR mode, -1 means "compute from width  & ratio"
  final int jpegQuality;
  final bool preventUpscale;
  final bool maintainAspectRatio;
  final img.Interpolation interpolation;
  final _AspectPayload? aspectPayload; // null = free resize (may distort)
  final bool forceJpeg;

  _ResizeArgs({
    required this.path,
    required this.width,
    required this.height,
    required this.jpegQuality,
    required this.preventUpscale,
    required this.maintainAspectRatio,
    required this.interpolation,
    required this.aspectPayload,
    required this.forceJpeg,
  });
}

class _ResizeResult {
  final List<int> bytes;
  final int width;
  final int height;
  final String ext; // 'jpg' or 'png'
  _ResizeResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.ext,
  });
}

_ResizeResult _resizeIsolate(_ResizeArgs a) {
  try {
    final bytes = File(a.path).readAsBytesSync();
    if (bytes.isEmpty) {
      throw Exception('Empty file');
    }

    final decoded0 = img.decodeImage(bytes);
    if (decoded0 == null) {
      throw Exception('Unsupported image format or corrupted file');
    }

    // EXIF orientation bake so dimensions match what users see
    img.Image work = img.bakeOrientation(decoded0);

    if (a.aspectPayload != null) {
      // ===== Aspect-Ratio path (no distortion) =====
      final ap = a.aspectPayload!;
      final targetRatio = ap.aspectW / ap.aspectH;
      final srcW = work.width, srcH = work.height;
      final srcRatio = srcW / srcH;

      // 1) Enforce the ratio via crop or pad
      if (ap.mode == AspectMode.fillCrop) {
        if (srcRatio > targetRatio) {
          final newW = (srcH * targetRatio).round();
          final x = ((srcW - newW) / 2).round();
          work = img.copyCrop(work, x: x, y: 0, width: newW, height: srcH);
        } else {
          final newH = (srcW / targetRatio).round();
          final y = ((srcH - newH) / 2).round();
          work = img.copyCrop(work, x: 0, y: y, width: srcW, height: newH);
        }
      } else {
        // Fit (pad) to the ratio
        int canvasW, canvasH;
        if (srcRatio > targetRatio) {
          canvasW = srcW;
          canvasH = (srcW / targetRatio).round();
        } else {
          canvasH = srcH;
          canvasW = (srcH * targetRatio).round();
        }
        final bg = img.Image(width: canvasW, height: canvasH);

        // Optional solid fill (ARGB). If null, stays transparent.
        if (ap.padColorArgb != null) {
          final aA = (ap.padColorArgb! >> 24) & 0xFF;
          final rA = (ap.padColorArgb! >> 16) & 0xFF;
          final gA = (ap.padColorArgb! >> 8) & 0xFF;
          final bA = (ap.padColorArgb!) & 0xFF;
          for (int y = 0; y < canvasH; y++) {
            for (int x = 0; x < canvasW; x++) {
              bg.setPixelRgba(x, y, rA, gA, bA, aA);
            }
          }
        }

        final dx = ((canvasW - srcW) / 2).round();
        final dy = ((canvasH - srcH) / 2).round();
        img.compositeImage(bg, work, dstX: dx, dstY: dy);
        work = bg;
      }

      // 2) Compute desired output box from primary dimension rule
      int desiredW, desiredH;
      if (ap.targetIsWidth) {
        desiredW = a.width; // passed in AR call
        desiredH = (desiredW / targetRatio).round();
      } else {
        desiredH = a.height; // passed in AR call
        desiredW = (desiredH * targetRatio).round();
      }

      // 3) Choose scale factor:
      //    - If forcePrimaryExact, make primary exact even if upscaling.
      //    - Else, fit inside desired box; respect preventUpscale.
      double scale;
      if (ap.forcePrimaryExact) {
        scale = ap.targetIsWidth
            ? desiredW / work.width
            : desiredH / work.height;
      } else {
        final sW = desiredW / work.width;
        final sH = desiredH / work.height;
        scale = math.min(sW, sH);
        if (a.preventUpscale) scale = math.min(scale, 1.0);
      }

      int outW = math.max(1, (work.width * scale).round());
      int outH = math.max(1, (work.height * scale).round());

      work = img.copyResize(
        work,
        width: outW,
        height: outH,
        interpolation: a.interpolation,
      );
    } else {
      // ===== Free resize path (may stretch if maintainAspectRatio=false) =====
      int w = a.width;
      int h = a.height;

      if (a.maintainAspectRatio) {
        // Fit inside target box with one scale factor (no distortion)
        final s = math.min(w / work.width, h / work.height);
        w = math.max(1, (work.width * s).round());
        h = math.max(1, (work.height * s).round());
      }

      if (a.preventUpscale) {
        final s = math.min(1.0, math.min(w / work.width, h / work.height));
        w = math.max(1, (work.width * s).round());
        h = math.max(1, (work.height * s).round());
      }

      work = img.copyResize(
        work,
        width: w,
        height: h,
        interpolation: a.interpolation,
      );
    }

    // Encode smartly: keep PNG if alpha (unless forced JPEG)
    final hasAlpha = work.hasAlpha;
    late List<int> outBytes;
    late String ext;
    if (!hasAlpha || a.forceJpeg) {
      final q = a.jpegQuality.clamp(1, 100);
      outBytes = img.encodeJpg(work, quality: q);
      ext = 'jpg';
    } else {
      outBytes = img.encodePng(work);
      ext = 'png';
    }

    return _ResizeResult(
      bytes: outBytes,
      width: work.width,
      height: work.height,
      ext: ext,
    );
  } catch (e) {
    throw Exception('Image resize failed: ${e.toString()}');
  }
}
