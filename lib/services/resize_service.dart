// lib/services/resize_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // compute
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ResizeOutput {
  final File file;
  final int width;
  final int height;
  final String ext; // ".jpg" | ".png" | ".gif"
  ResizeOutput({
    required this.file,
    required this.width,
    required this.height,
    required this.ext,
  });
}

/// Resizes an image file to EXACT [width]×[height] (no aspect preservation).
/// - CPU work (decode/orient/resize/encode) on a background isolate
/// - File write on main isolate
class ResizeService {
  static Future<ResizeOutput> resizeFileExact({
    required String inputPath,
    required int width,
    required int height,
    int jpegQuality = 90,
    bool preventUpscale = false, // allow stretching by default
  }) async {
    // 1) CPU-only in background isolate
    final result = await compute<_ResizeParams, _ResizeResult>(
      _resizeInIsolate,
      _ResizeParams(
        path: inputPath,
        width: width,
        height: height,
        jpegQuality: jpegQuality,
        preventUpscale: preventUpscale,
      ),
    );

    // 2) Back on main isolate: write to temp dir
    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      '${p.basenameWithoutExtension(inputPath)}_${result.outWidth}x${result.outHeight}${result.ext}',
    );

    final outFile = File(outPath);
    await outFile.writeAsBytes(result.bytes, flush: true);

    return ResizeOutput(
      file: outFile,
      width: result.outWidth,
      height: result.outHeight,
      ext: result.ext,
    );
  }
}

/// ===== Isolate payloads =====
class _ResizeParams {
  final String path;
  final int width;
  final int height;
  final int jpegQuality;
  final bool preventUpscale;
  const _ResizeParams({
    required this.path,
    required this.width,
    required this.height,
    required this.jpegQuality,
    required this.preventUpscale,
  });
}

class _ResizeResult {
  final Uint8List bytes;
  final String ext; // ".jpg" | ".png" | ".gif"
  final int outWidth;
  final int outHeight;
  const _ResizeResult(this.bytes, this.ext, this.outWidth, this.outHeight);
}

/// ===== Isolate entry (TOP-LEVEL; NO plugins here) =====
Future<_ResizeResult> _resizeInIsolate(_ResizeParams params) async {
  final fileBytes = await File(params.path).readAsBytes();

  final decoded = img.decodeImage(fileBytes);
  if (decoded == null) {
    throw Exception('Unsupported or corrupted image.');
  }

  // fix EXIF orientation first
  final oriented = img.bakeOrientation(decoded);
  final origW = oriented.width;
  final origH = oriented.height;

  int w = params.width;
  int h = params.height;

  // optionally clamp to avoid upscaling
  if (params.preventUpscale) {
    if (w > origW) w = origW;
    if (h > origH) h = origH;
  }

  // EXACT resize: no aspect preservation
  final resized = img.copyResize(oriented, width: w, height: h);

  // choose format based on original (fallback to jpg)
  final origExt = p.extension(params.path).toLowerCase();
  late List<int> outBytes;
  late String outExt;

  if (origExt == '.png') {
    outBytes = img.encodePng(resized);
    outExt = '.png';
  } else if (origExt == '.gif') {
    outBytes = img.encodeGif(resized); // static only
    outExt = '.gif';
  } else {
    outBytes = img.encodeJpg(resized, quality: params.jpegQuality);
    outExt = '.jpg';
  }

  return _ResizeResult(
    Uint8List.fromList(outBytes),
    outExt,
    resized.width,
    resized.height,
  );
}
