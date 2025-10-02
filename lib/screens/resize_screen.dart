// lib/screens/resize_screen.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:snapalyze/shared/app_theme.dart';

import 'package:snapalyze/models/pickedimage_model.dart';
import 'package:snapalyze/services/resize_service.dart';
import 'package:snapalyze/shared/utilis.dart';

class ResizeScreen extends StatefulWidget {
  static const String routeName = '/resizescreen';
  const ResizeScreen({super.key});

  @override
  State<ResizeScreen> createState() => _ResizeScreenState();
}

class _ResizeScreenState extends State<ResizeScreen> {
  // --- Shared ---
  PickedimageModel? _picked;
  Size? _originalSize;

  // --- Width x Height section ---
  final _dimFormKey = GlobalKey<FormState>();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController();
  bool _loadingDim = false;
  ResizeOutput? _dimResult;

  // --- Aspect Ratio section ---
  final _arFormKey = GlobalKey<FormState>();
  final _arWCtrl = TextEditingController(text: '1');
  final _arHCtrl = TextEditingController(text: '1');
  final _targetCtrl = TextEditingController();
  bool _targetIsWidth = true;
  bool _loadingAR = false;
  ResizeOutput? _arResult;

  // --- Fill section ---
  final _fillFormKey = GlobalKey<FormState>();
  final _fillWCtrl = TextEditingController();
  final _fillHCtrl = TextEditingController();
  bool _loadingFill = false;
  ResizeOutput? _fillResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_picked == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PickedimageModel) {
        _picked = args;
        _loadOriginalSize();
      }
    }
  }

  Future<void> _loadOriginalSize() async {
    if (_picked == null) return;

    final size = await getImageSize(_picked!.pickedImage);
    if (mounted) {
      setState(() {
        _originalSize = size;
      });
    }
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    _arWCtrl.dispose();
    _arHCtrl.dispose();
    _targetCtrl.dispose();
    _fillWCtrl.dispose();
    _fillHCtrl.dispose();
    super.dispose();
  }

  Future<Size> getImageSize(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final fi = await codec.getNextFrame();
      return Size(fi.image.width.toDouble(), fi.image.height.toDouble());
    } catch (e) {
      // Fallback: get dimensions from file path analysis if available
      final results = _picked?.results;
      if (results != null && results['analysis']['dimensions'] != null) {
        final dimensions = results['analysis']['dimensions'].split('x');
        if (dimensions.length == 2) {
          return Size(double.parse(dimensions[0]), double.parse(dimensions[1]));
        }
      }
      return const Size(300, 300); // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final PickedimageModel image =
        ModalRoute.of(context)!.settings.arguments as PickedimageModel;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        title: const Text('Resize Image'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ====== INPUT PREVIEW (original image) ======
                if (_picked?.pickedImage != null)
                  _card(
                    textTheme: textTheme,

                    title:
                        'Original ${_originalSize != null ? '(${_originalSize!.width.round()}×${_originalSize!.height.round()})' : ''}',

                    child: FutureBuilder<Size>(
                      future: getImageSize(image.pickedImage),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return SizedBox(
                            width: size.width * 0.7,
                            height: size.height * 0.4,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final ar = snap.data!.width / snap.data!.height;

                        return Container(
                          width: size.width * 0.7,
                          // height scales automatically from AspectRatio
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: AspectRatio(
                              aspectRatio: ar,
                              child: Image.file(
                                image.pickedImage,
                                fit: BoxFit.contain,
                                frameBuilder:
                                    (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        child: frame == null
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : child,
                                      );
                                    },
                                errorBuilder: (context, error, stack) => Center(
                                  child: Text(
                                    'Failed to load image',
                                    style: textTheme.titleSmall?.copyWith(
                                      color: AppTheme.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // ====== SECTION 1: By Width × Height ======
                _card(
                  textTheme: textTheme,

                  title: 'Resize by Width × Height',
                  subtitle: 'Stretches image to exact dimensions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: _dimFormKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: _customTextFeild(
                                textTheme: textTheme,
                                hint:
                                    _originalSize?.width.round().toString() ??
                                    'Width',
                                label: 'Width (px)',
                                controller: _wCtrl,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = int.tryParse(v) ?? 0;
                                  if (n <= 0) return 'Must be > 0';
                                  if (n > 8192) return 'Max 8192';
                                  return null;
                                },
                                enabled: !_loadingDim,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _customTextFeild(
                                textTheme: textTheme,
                                hint:
                                    _originalSize?.height.round().toString() ??
                                    'Height',
                                label: 'Height (px)',
                                controller: _hCtrl,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = int.tryParse(v) ?? 0;
                                  if (n <= 0) return 'Must be > 0';
                                  if (n > 8192) return 'Max 8192';
                                  return null;
                                },
                                enabled: !_loadingDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                        icon: Icons.photo_size_select_large_outlined,

                        label: 'Resize Exact',
                        onPressed: (_picked != null && !_loadingDim)
                            ? _onResizeByDimensions
                            : null,
                      ),
                      if (_loadingDim) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(color: AppTheme.primary),
                      ],
                      if (_dimResult != null) ...[
                        const SizedBox(height: 12),
                        _resultPreview(_dimResult!, textTheme),
                        const SizedBox(height: 8),
                        _outlineButton(
                          icon: Icons.save_alt,
                          label: 'Save to Gallery',
                          onPressed: () => _saveToGallery(_dimResult!.file),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ====== SECTION 2: Fill Exact Dimensions ======
                _card(
                  textTheme: textTheme,

                  title: 'Fill Exact Dimensions',
                  subtitle: 'Crops image to fill without distortion',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Form(
                        key: _fillFormKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: _customTextFeild(
                                textTheme: textTheme,
                                hint:
                                    _originalSize?.width.round().toString() ??
                                    'Width',
                                label: 'Width (px)',
                                controller: _fillWCtrl,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = int.tryParse(v) ?? 0;
                                  if (n <= 0) return 'Must be > 0';
                                  if (n > 8192) return 'Max 8192';
                                  return null;
                                },
                                enabled: !_loadingFill,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _customTextFeild(
                                textTheme: textTheme,
                                hint:
                                    _originalSize?.height.round().toString() ??
                                    'Height',
                                label: 'Height (px)',
                                controller: _fillHCtrl,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final n = int.tryParse(v) ?? 0;
                                  if (n <= 0) return 'Must be > 0';
                                  if (n > 8192) return 'Max 8192';
                                  return null;
                                },
                                enabled: !_loadingFill,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                        icon: Icons.crop,
                        label: 'Fill Dimensions',
                        onPressed: (_picked != null && !_loadingFill)
                            ? _onResizeFill
                            : null,
                      ),
                      if (_loadingFill) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(color: AppTheme.primary),
                      ],
                      if (_fillResult != null) ...[
                        const SizedBox(height: 12),
                        _resultPreview(_fillResult!, textTheme),
                        const SizedBox(height: 8),
                        _outlineButton(
                          icon: Icons.save_alt,
                          label: 'Save to Gallery',
                          onPressed: () => _saveToGallery(_fillResult!.file),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ====== SECTION 3: By Aspect Ratio ======
                _card(
                  title: 'Resize by Aspect Ratio',
                  subtitle: 'Crops to aspect ratio then scales',
                  textTheme: textTheme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // quick presets
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ratioChip('1:1', 1, 1),
                          _ratioChip('4:3', 4, 3),
                          _ratioChip('3:4', 3, 4),
                          _ratioChip('3:2', 3, 2),
                          _ratioChip('16:9', 16, 9),
                          _ratioChip('9:16', 9, 16),
                          _ratioChip('2:3', 2, 3),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Form(
                        key: _arFormKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _customTextFeild(
                                    textTheme: textTheme,
                                    label: 'AR Width',
                                    controller: _arWCtrl,
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '') ?? 0;
                                      if (n <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                    enabled: !_loadingAR,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _customTextFeild(
                                    textTheme: textTheme,
                                    label: 'AR Height',
                                    controller: _arHCtrl,
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '') ?? 0;
                                      if (n <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                    enabled: !_loadingAR,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            RadioGroup<bool>.row(
                              value: _targetIsWidth,
                              onChanged: _loadingAR
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => _targetIsWidth = v);
                                        _targetCtrl.text =
                                            ''; // Clear target when switching
                                      }
                                    },
                              children: [
                                RadioOption(
                                  value: true,
                                  label: Text(
                                    'Target is Width',
                                    style: textTheme.titleMedium!.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                RadioOption(
                                  value: false,
                                  label: Text(
                                    'Target is Height',
                                    style: textTheme.titleMedium!.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _customTextFeild(
                              textTheme: textTheme,
                              label: _targetIsWidth
                                  ? 'Target Width (px)'
                                  : 'Target Height (px)',
                              hint: _targetIsWidth ? 'e.g., 800' : 'e.g., 600',
                              controller: _targetCtrl,
                              validator: (v) {
                                final n = int.tryParse(v ?? '') ?? 0;
                                if (n <= 0) return 'Must be > 0';
                                if (n > 8192) return 'Max 8192';
                                return null;
                              },
                              enabled: !_loadingAR,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton(
                        icon: Icons.aspect_ratio,
                        label: 'Resize by Aspect',
                        onPressed: (_picked != null && !_loadingAR)
                            ? _onResizeByAspect
                            : null,
                      ),

                      if (_loadingAR) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(color: AppTheme.primary),
                      ],

                      if (_arResult != null) ...[
                        const SizedBox(height: 12),
                        _resultPreview(_arResult!, textTheme),
                        const SizedBox(height: 8),
                        _outlineButton(
                          icon: Icons.save_alt,
                          label: 'Save to Gallery',
                          onPressed: () => _saveToGallery(_arResult!.file),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ===== Actions =====

  Future<void> _onResizeByDimensions() async {
    if (_picked == null) return;
    if (!_dimFormKey.currentState!.validate()) return;

    setState(() {
      _loadingDim = true;
      _dimResult = null;
    });

    try {
      final width = int.parse(_wCtrl.text);
      final height = int.parse(_hCtrl.text);

      final out = await ResizeService().resizeExact(
        path: _picked!.pickedImage.path,
        width: width,
        height: height,
        jpegQuality: 90,

        quality: ResizeQuality.balanced,
      );

      if (!mounted) return;
      setState(() => _dimResult = out);
      Utilis.showSuccessMessage('Image resized to exact dimensions.');
    } catch (e) {
      Utilis.showErrorMessage('Resize failed: $e');
    } finally {
      if (mounted) setState(() => _loadingDim = false);
    }
  }

  Future<void> _onResizeFill() async {
    if (_picked == null) return;
    if (!_fillFormKey.currentState!.validate()) return;

    setState(() {
      _loadingFill = true;
      _fillResult = null;
    });

    try {
      final width = int.parse(_fillWCtrl.text);
      final height = int.parse(_fillHCtrl.text);

      final out = await ResizeService().resizeFill(
        path: _picked!.pickedImage.path,
        width: width,
        height: height,
        jpegQuality: 90,
        quality: ResizeQuality.smooth,
      );

      if (!mounted) return;
      setState(() => _fillResult = out);
      Utilis.showSuccessMessage('Image filled to exact dimensions (cropped).');
    } catch (e) {
      Utilis.showErrorMessage('Fill resize failed: $e');
    } finally {
      if (mounted) setState(() => _loadingFill = false);
    }
  }

  Future<void> _onResizeByAspect() async {
    if (_picked == null) return;
    if (!_arFormKey.currentState!.validate()) return;

    setState(() {
      _loadingAR = true;
      _arResult = null;
    });

    try {
      final int arW = int.parse(_arWCtrl.text);
      final int arH = int.parse(_arHCtrl.text);
      final int target = int.parse(_targetCtrl.text);

      final ResizeOutput out = await ResizeService().resizeByAspect(
        path: _picked!.pickedImage.path,
        aspectW: arW,
        aspectH: arH,
        target: target,
        targetIsWidth: _targetIsWidth,
        jpegQuality: 90,
        preventUpscale: false,
        quality: ResizeQuality.smooth,
      );

      if (!mounted) return;
      Utilis.showSuccessMessage('Image resized with aspect ratio.');
      setState(() {
        _arResult = out;
      });
    } catch (e) {
      Utilis.showErrorMessage('Aspect ratio resize failed: $e');
    } finally {
      if (mounted) setState(() => _loadingAR = false);
    }
  }

  Future<void> _saveToGallery(File f) async {
    try {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        Utilis.showErrorMessage('Permission denied to save image.');
        return;
      }
      await ImageGallerySaverPlus.saveFile(f.path);
      Utilis.showSuccessMessage('Saved to gallery.');
    } catch (e) {
      Utilis.showErrorMessage('Save failed: $e');
    }
  }

  // ===== UI helpers =====

  Widget _customTextFeild({
    required TextTheme textTheme,
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    required bool enabled,
    String? hint,
  }) {
    return TextFormField(
      style: textTheme.titleMedium!.copyWith(color: AppTheme.primary),
      cursorColor: AppTheme.primary,
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: textTheme.titleMedium!.copyWith(
          color: AppTheme.primary.withValues(alpha: 0.7),
        ),
        labelStyle: textTheme.titleMedium!.copyWith(color: AppTheme.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.red, width: 2),
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _card({
    required TextTheme textTheme,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 1.5,
      color: AppTheme.white,
      shadowColor: AppTheme.grey.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.grey.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.titleSmall!.copyWith(
                      color: AppTheme.black,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.white),
        label: Text(label, style: const TextStyle(color: AppTheme.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.grey.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primary),
        label: Text(label, style: TextStyle(color: AppTheme.primary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _ratioChip(String label, int w, int h) {
    final isSelected = _arWCtrl.text == '$w' && _arHCtrl.text == '$h';
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.black,
      ),
      selectedColor: AppTheme.primary,
      checkmarkColor: AppTheme.white,
      backgroundColor: AppTheme.grey.withValues(alpha: 0.15),
      onSelected: (_) {
        setState(() {
          _arWCtrl.text = '$w';
          _arHCtrl.text = '$h';
        });
      },
    );
  }

  Widget _resultPreview(ResizeOutput result, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Result: ${result.width}×${result.height}',
          style: textTheme.titleSmall?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              result.file,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== RadioGroup (keep your existing implementation) =====
class RadioOption<T> {
  final T value;
  final Widget label;
  const RadioOption({required this.value, required this.label});
}

class RadioGroup<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T?>? onChanged;
  final List<RadioOption<T>> children;

  const RadioGroup.row({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: children.map((opt) {
        final selected = opt.value == value;
        final disabled = onChanged == null;

        final tile = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: disabled ? theme.disabledColor : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            DefaultTextStyle.merge(
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
              child: opt.label,
            ),
          ],
        );

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled ? null : () => onChanged?.call(opt.value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: tile,
            ),
          ),
        );
      }).toList(),
    );
  }
}
