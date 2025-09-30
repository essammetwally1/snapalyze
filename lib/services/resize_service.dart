// lib/services/resize_service.dart
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

/// Resample quality presets
enum ResizeQuality {
  fast(img.Interpolation.average),
  balanced(img.Interpolation.linear),
  smooth(img.Interpolation.cubic);

  const ResizeQuality(this.interpolation);
  final img.Interpolation interpolation;
}

class ResizeService {
  static const _maxDimension = 8192;

  /// Manual resize to **exact** width × height (will stretch if aspect differs).
  Future<ResizeOutput> resizeExact({
    required String path,
    required int width,
    required int height,
    int jpegQuality = 90,
    bool forceJpeg = false, // if true, always outputs JPEG (drops alpha)
    ResizeQuality quality = ResizeQuality.balanced,
  }) async {
    _validateWH(width, height);

    final res = await compute<_Args, _Res>(
      _isolate,
      _Args.stretch(
        path: path,
        width: width,
        height: height,
        interpolation: quality.interpolation,
        jpegQuality: jpegQuality,
        forceJpeg: forceJpeg,
      ),
    );

    final outFile = await _writeTemp(res.bytes, res.ext);
    return ResizeOutput(file: outFile, width: res.w, height: res.h);
  }

  /// Resize by **aspect ratio** with **primary side exact**.
  ///
  /// - Provide ratio as [aspectW]:[aspectH].
  /// - If [targetIsWidth] is true, output **width = target** exactly,
  ///   and height is computed from the ratio (and vice-versa).
  /// - We **center-crop** the original to the requested ratio (no distortion),
  ///   then scale to hit the exact target side.
  ///
  /// Set [preventUpscale]=true if you prefer not to enlarge small images.
  /// (In that case, the primary side may end up smaller than target.)
  Future<ResizeOutput> resizeByAspect({
    required String path,
    required int aspectW,
    required int aspectH,
    required int target,
    required bool targetIsWidth,
    bool preventUpscale = false,
    int jpegQuality = 90,
    bool forceJpeg = false,
    ResizeQuality quality = ResizeQuality.smooth,
  }) async {
    assert(aspectW > 0 && aspectH > 0 && target > 0);
    _validateDim(target);

    final res = await compute<_Args, _Res>(
      _isolate,
      _Args.aspectPrimaryExact(
        path: path,
        arW: aspectW,
        arH: aspectH,
        target: target,
        targetIsWidth: targetIsWidth,
        preventUpscale: preventUpscale,
        interpolation: quality.interpolation,
        jpegQuality: jpegQuality,
        forceJpeg: forceJpeg,
      ),
    );

    final outFile = await _writeTemp(res.bytes, res.ext);
    return ResizeOutput(file: outFile, width: res.w, height: res.h);
  }

  // ---------- validation & file helpers ----------

  void _validateDim(int n) {
    if (n <= 0) throw Exception('Dimension must be > 0');
    if (n > _maxDimension) {
      throw Exception('Dimension cannot exceed $_maxDimension');
    }
  }

  void _validateWH(int w, int h) {
    _validateDim(w);
    _validateDim(h);
    if (w * h > _maxDimension * _maxDimension) {
      throw Exception('Total pixel count exceeds maximum allowed');
    }
  }

  Future<File> _writeTemp(List<int> bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final p =
        '${dir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final f = File(p);
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }
}

// ================= isolate types & worker =================

class _Args {
  final String path;
  final img.Interpolation interpolation;
  final int jpegQuality;
  final bool forceJpeg;

  // stretch (exact WxH, may distort)
  final int? width;
  final int? height;

  // aspect primary exact (no distortion; crop to ratio, then scale)
  final int? arW;
  final int? arH;
  final int? target;
  final bool? targetIsWidth;
  final bool? preventUpscale;

  _Args._({
    required this.path,
    required this.interpolation,
    required this.jpegQuality,
    required this.forceJpeg,
    this.width,
    this.height,
    this.arW,
    this.arH,
    this.target,
    this.targetIsWidth,
    this.preventUpscale,
  });

  factory _Args.stretch({
    required String path,
    required int width,
    required int height,
    required img.Interpolation interpolation,
    required int jpegQuality,
    required bool forceJpeg,
  }) => _Args._(
    path: path,
    width: width,
    height: height,
    interpolation: interpolation,
    jpegQuality: jpegQuality,
    forceJpeg: forceJpeg,
  );

  factory _Args.aspectPrimaryExact({
    required String path,
    required int arW,
    required int arH,
    required int target,
    required bool targetIsWidth,
    required bool preventUpscale,
    required img.Interpolation interpolation,
    required int jpegQuality,
    required bool forceJpeg,
  }) => _Args._(
    path: path,
    arW: arW,
    arH: arH,
    target: target,
    targetIsWidth: targetIsWidth,
    preventUpscale: preventUpscale,
    interpolation: interpolation,
    jpegQuality: jpegQuality,
    forceJpeg: forceJpeg,
  );
}

class _Res {
  final List<int> bytes;
  final int w;
  final int h;
  final String ext; // 'jpg' or 'png'
  _Res(this.bytes, this.w, this.h, this.ext);
}

_Res _encode(img.Image im, int jpegQuality, bool forceJpeg) {
  final hasAlpha = im.hasAlpha;
  if (!hasAlpha || forceJpeg) {
    final q = jpegQuality.clamp(1, 100);
    final jpg = img.encodeJpg(im, quality: q);
    return _Res(jpg, im.width, im.height, 'jpg');
  }
  final png = img.encodePng(im);
  return _Res(png, im.width, im.height, 'png');
}

_Res _isolate(_Args a) {
  final data = File(a.path).readAsBytesSync();
  if (data.isEmpty) throw Exception('Empty file');

  final decoded0 = img.decodeImage(data);
  if (decoded0 == null) throw Exception('Unsupported or corrupt image');

  // Bake EXIF so width/height reflect what users see
  img.Image work = img.bakeOrientation(decoded0);

  // ---- Mode 1: Stretch to exact WxH ----
  if (a.width != null && a.height != null && a.arW == null) {
    work = img.copyResize(
      work,
      width: a.width!,
      height: a.height!,
      interpolation: a.interpolation,
    );
    return _encode(work, a.jpegQuality, a.forceJpeg);
  }

  // ---- Mode 2: Aspect-ratio with primary exact (no distortion) ----
  if (a.arW != null &&
      a.arH != null &&
      a.target != null &&
      a.targetIsWidth != null) {
    final targetRatio = a.arW! / a.arH!;
    final srcW = work.width, srcH = work.height;
    final srcRatio = srcW / srcH;

    // 1) Center-crop to the requested ratio (no distortion)
    if (srcRatio > targetRatio) {
      // too wide: crop width
      final newW = (srcH * targetRatio).round();
      final x = ((srcW - newW) / 2).round();
      work = img.copyCrop(work, x: x, y: 0, width: newW, height: srcH);
    } else if (srcRatio < targetRatio) {
      // too tall: crop height
      final newH = (srcW / targetRatio).round();
      final y = ((srcH - newH) / 2).round();
      work = img.copyCrop(work, x: 0, y: y, width: srcW, height: newH);
    }
    // at this point, work.width/work.height == targetRatio (within rounding)

    // 2) Compute desired output dimensions from target side
    int desiredW, desiredH;
    if (a.targetIsWidth!) {
      desiredW = a.target!;
      desiredH = (desiredW / targetRatio).round();
    } else {
      desiredH = a.target!;
      desiredW = (desiredH * targetRatio).round();
    }

    // 3) Choose scale factor
    double scale = a.targetIsWidth!
        ? desiredW / work.width
        : desiredH / work.height;

    if (a.preventUpscale == true) {
      scale = math.min(scale, 1.0); // don't enlarge beyond current
    }

    final outW = math.max(1, (work.width * scale).round());
    final outH = math.max(1, (work.height * scale).round());

    work = img.copyResize(
      work,
      width: outW,
      height: outH,
      interpolation: a.interpolation,
    );

    return _encode(work, a.jpegQuality, a.forceJpeg);
  }

  // Fallback: just encode the original
  return _encode(work, a.jpegQuality, a.forceJpeg);
}
