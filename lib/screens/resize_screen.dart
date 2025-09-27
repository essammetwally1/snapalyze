// lib/screens/resize_screen.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FilteringTextInputFormatter
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:snapalyze/app_theme.dart';
import 'package:snapalyze/models/pickedimage_model.dart';
import 'package:snapalyze/services/resize_service.dart';
import 'package:snapalyze/utilis.dart';

class ResizeScreen extends StatefulWidget {
  static const String routeName = '/resizescreen';
  const ResizeScreen({super.key});

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  File? _resizedFile;
  int? _resizedW;
  int? _resizedH;

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  /// Read actual size for the original preview's true aspect ratio
  Future<Size> _getImageSize(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final fi = await codec.getNextFrame();
    return Size(fi.image.width.toDouble(), fi.image.height.toDouble());
  }

  Future<void> _onResize(File pickedImage) async {
    // REQUIRE both width & height (exact resize)
    final width = int.tryParse(_wCtrl.text.trim());
    final height = int.tryParse(_hCtrl.text.trim());
    if (width == null || width <= 0 || height == null || height <= 0) {
      setState(() => _error = 'Enter valid width and height.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _resizedFile = null;
      _resizedW = null;
      _resizedH = null;
    });

    try {
      final out = await ResizeService.resizeFileExact(
        inputPath: pickedImage.path,
        width: width,
        height: height,
        jpegQuality: 90,
        preventUpscale: false, // you want exact numbers, allow stretching
      );

      setState(() {
        _resizedFile = out.file;
        _resizedW = out.width;
        _resizedH = out.height;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_resizedFile == null) return;

    // ---- Ask for the right permission depending on platform/version ----
    PermissionStatus status;

    if (Platform.isAndroid) {
      // Try the Android 13+ photos permission first (maps to READ_MEDIA_IMAGES)
      status = await Permission.photos.request();

      // On older Androids, `photos` may be denied/not applicable → fall back to storage
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      // iOS uses Photos permission via `photos`
      status = await Permission.photos.request();
    } else {
      // Other platforms: proceed without permission (or handle as you need)
      status = PermissionStatus.granted;
    }

    if (!status.isGranted) {
      Utilis.showErrorMessage('Gallery permission denied');
      return;
    }

    try {
      final result = await ImageGallerySaverPlus.saveFile(_resizedFile!.path);

      // result is usually a Map with {isSuccess: true/false, filePath: ...}
      final ok = result['isSuccess'] == true;
      if (ok) {
        Utilis.showSuccessMessage('Saved to gallery');
      } else {
        Utilis.showErrorMessage('Failed to save');
      }
    } catch (e) {
      Utilis.showErrorMessage('Save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // expecting this in arguments
    final PickedimageModel picked =
        ModalRoute.of(context)!.settings.arguments as PickedimageModel;

    // prefill hints like "1920x1080"
    final String imageSize = picked.results['analysis']['dimensions'];
    final parts = imageSize.split('x');
    final hintW = parts.isNotEmpty ? parts[0] : '';
    final hintH = parts.length > 1 ? parts[1] : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Resize",
          style: textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- Original preview (true ratio) ----------
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Original'),
                  const SizedBox(height: 8),
                  FutureBuilder<Size>(
                    future: _getImageSize(picked.pickedImage),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final ar = snap.data!.width / snap.data!.height;
                      return AspectRatio(
                        aspectRatio: ar,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            picked.pickedImage,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Form ----------
            _Card(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemedNumberField(
                            controller: _wCtrl,
                            label: 'Width (px)',
                            hint: hintW,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Enter valid width';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ThemedNumberField(
                            controller: _hCtrl,
                            label: 'Height (px)',
                            hint: hintH,
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Enter valid height';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Will resize exactly to W×H (may stretch).',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---------- Resize button ----------
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _onResize(picked.pickedImage),
              icon: const Icon(Icons.photo_size_select_large),
              label: Text(_loading ? 'Resizing……' : 'Resize'),
            ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                color: AppTheme.primary,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.red)),
            ],

            const SizedBox(height: 16),

            // ---------- Resized preview shown at EXACT entered ratio ----------
            if (_resizedFile != null && _resizedW != null && _resizedH != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  // scale down to fit width & keep entered ratio, but DO NOT preserve original
                  final scale = (_resizedW! > 0)
                      ? (maxW / _resizedW!).clamp(0.0, 1.0)
                      : 1.0;
                  final displayW = _resizedW! * scale;
                  final displayH = _resizedH! * scale;

                  return _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Resized $_resizedW×$_resizedH'),
                        const SizedBox(height: 8),
                        Center(
                          child: SizedBox(
                            width: displayW,
                            height: displayH,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _resizedFile!,
                                fit: BoxFit.fill, // <- EXACT W×H box fill
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _saveToGallery,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save to Gallery'),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// ------------ UI helpers (Themed) ------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ThemedNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _ThemedNumberField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return TextFormField(
      cursorColor: AppTheme.white,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.titleMedium,
        hintText: hint,
        hintStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.red),
        ),
        isDense: true,
        fillColor: Colors.transparent,
        filled: true,
      ),
      validator: validator,
    );
  }
}
