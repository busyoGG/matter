import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/home_background_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/frosted_header_background.dart';

class HomeBackgroundSettingsPage extends ConsumerStatefulWidget {
  const HomeBackgroundSettingsPage({super.key});

  @override
  ConsumerState<HomeBackgroundSettingsPage> createState() =>
      _HomeBackgroundSettingsPageState();
}

class _HomeBackgroundSettingsPageState
    extends ConsumerState<HomeBackgroundSettingsPage> {
  final _picker = ImagePicker();
  bool _busy = false;

  double? _imageOpacityDraft;
  double? _cardBlurSigmaDraft;
  double? _darkenStrengthDraft;

  Future<void> _pick(HomeBackgroundVariant variant) async {
    if (_busy) return;
    if (kIsWeb) {
      _showMessage('当前平台不支持本地首页背景');
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null) return;
      final extension = _extensionOf(picked.name);
      await ref
          .read(homeBackgroundProvider.notifier)
          .setBackground(
            await picked.readAsBytes(),
            extension: extension,
            variant: variant,
          );
      if (mounted) {
        _showMessage(
          variant == HomeBackgroundVariant.dark ? '深色模式背景已更新' : '浅色模式背景已更新',
        );
      }
    } on UnsupportedError {
      _showMessage('当前平台不支持本地首页背景');
    } on MissingPluginException {
      _showMessage('当前平台不支持选择图片');
    } catch (error) {
      if (mounted) _showMessage('保存背景失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear(HomeBackgroundVariant variant) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(homeBackgroundProvider.notifier)
          .clearBackground(variant: variant);
      if (mounted) {
        _showMessage(
          variant == HomeBackgroundVariant.dark ? '深色模式背景已清除' : '浅色模式背景已清除',
        );
      }
    } catch (error) {
      if (mounted) _showMessage('清除背景失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commitImageOpacity(double value) async {
    try {
      await ref.read(homeBackgroundProvider.notifier).setImageOpacity(value);
    } catch (error) {
      if (mounted) _showMessage('保存背景透明度失败：$error');
    }
    if (mounted) setState(() => _imageOpacityDraft = null);
  }

  Future<void> _commitCardBlurSigma(double value) async {
    try {
      await ref.read(homeBackgroundProvider.notifier).setCardBlurSigma(value);
    } catch (error) {
      if (mounted) _showMessage('保存卡片模糊强度失败：$error');
    }
    if (mounted) setState(() => _cardBlurSigmaDraft = null);
  }

  Future<void> _commitDarkenStrength(double value) async {
    try {
      await ref.read(homeBackgroundProvider.notifier).setDarkenStrength(value);
    } catch (error) {
      if (mounted) _showMessage('保存压暗强度失败：$error');
    }
    if (mounted) setState(() => _darkenStrengthDraft = null);
  }

  Future<void> _setDarkenEnabled(bool value) async {
    try {
      await ref.read(homeBackgroundProvider.notifier).setDarkenEnabled(value);
    } catch (error) {
      if (mounted) _showMessage('保存压暗设置失败：$error');
    }
  }

  Widget _buildBackgroundTile(
    BuildContext context,
    HomeBackgroundState background,
    HomeBackgroundVariant variant,
  ) {
    final isDark = variant == HomeBackgroundVariant.dark;
    final path = isDark ? background.darkPath : background.path;
    return ListTile(
      onTap: _busy ? null : () => _pick(variant),
      leading: Icon(
        isDark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(isDark ? '深色模式背景' : '浅色模式背景'),
      subtitle: Text(path == null ? '未设置' : '已设置本地背景'),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (path != null)
                  IconButton(
                    tooltip: '清除背景',
                    onPressed: () => _clear(variant),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                IconButton(
                  tooltip: '选择图片',
                  onPressed: () => _pick(variant),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
              ],
            ),
    );
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final extension = name.substring(dot + 1).toLowerCase();
    return const {
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
        }.contains(extension)
        ? extension
        : 'jpg';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = ref.watch(homeBackgroundProvider);
    final imageOpacity = _imageOpacityDraft ?? background.imageOpacity;
    final cardBlurSigma = _cardBlurSigmaDraft ?? background.cardBlurSigma;
    final darkenStrength = _darkenStrengthDraft ?? background.darkenStrength;
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页背景'),
        backgroundColor: Colors.transparent,
        flexibleSpace: FrostedHeaderBackground(backgroundColor: colors.surface),
      ),
      backgroundColor: colors.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '四个首页共用背景。可分别设置浅色和深色模式图片，图片会复制到应用支持目录。',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildBackgroundTile(
                  context,
                  background,
                  HomeBackgroundVariant.light,
                ),
                const Divider(height: 1),
                _buildBackgroundTile(
                  context,
                  background,
                  HomeBackgroundVariant.dark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '背景图片不透明度 ${((imageOpacity) * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: imageOpacity,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(imageOpacity * 100).round()}%',
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _imageOpacityDraft = value),
                  onChangeEnd: _busy ? null : _commitImageOpacity,
                ),
                Text(
                  '卡片模糊强度 ${cardBlurSigma.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: cardBlurSigma,
                  min: 0,
                  max: homeBackgroundMaxBlurSigma,
                  divisions: homeBackgroundMaxBlurSigma.round(),
                  label: cardBlurSigma.toStringAsFixed(0),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _cardBlurSigmaDraft = value),
                  onChangeEnd: _busy ? null : _commitCardBlurSigma,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.brightness_4_outlined,
                    color: colors.primary,
                  ),
                  title: const Text('深色模式压暗背景'),
                  value: background.darkenEnabled,
                  onChanged: _busy ? null : _setDarkenEnabled,
                ),
                Text(
                  '压暗强度 ${((darkenStrength) * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: darkenStrength,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: '${(darkenStrength * 100).round()}%',
                  onChanged: !_busy && background.darkenEnabled
                      ? (value) => setState(() => _darkenStrengthDraft = value)
                      : null,
                  onChangeEnd: !_busy && background.darkenEnabled
                      ? _commitDarkenStrength
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
