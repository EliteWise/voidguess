import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:voidguess/core/l10n/l10n.dart';
import 'package:voidguess/core/provider/locale_provider.dart';
import 'package:voidguess/core/provider/sound_provider.dart';
import 'package:voidguess/core/theme/app_theme.dart';
import 'package:voidguess/core/widgets/pressable.dart';
import 'package:voidguess/core/widgets/void_action_button.dart';
import 'package:voidguess/data/services/hive_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final Future<PackageInfo> _packageInfo;
  bool _showNameError = false;
  bool _nameSaved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: HiveService().getPlayerName(),
    );
    _packageInfo = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _showNameError = true;
        _nameSaved = false;
      });
      return;
    }

    await HiveService().setPlayerName(name);
    if (!mounted) return;
    setState(() {
      _showNameError = false;
      _nameSaved = true;
    });
    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _nameSaved = false);
  }

  Future<void> _setSoundEnabled(bool enabled) async {
    ref.read(soundProvider.notifier).state = enabled;
    await HiveService().setSoundEnabled(enabled);
  }

  Future<void> _confirmDeleteData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.neutralRadius),
        title: Text(
          ref.tr('delete_data_title'),
          style: AppTheme.inter(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          ref.tr('delete_data_desc'),
          style: AppTheme.inter(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              ref.tr('cancel'),
              style: AppTheme.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              ref.tr('delete_data_confirm'),
              style: AppTheme.inter(
                color: AppTheme.wrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleteMessage = ref.tr('data_deleted');
    final hive = HiveService();
    await hive.deleteAllUserData();
    await hive.setLocale('fr');
    await hive.setSoundEnabled(false);

    ref.read(localeProvider.notifier).state = 'fr';
    ref.read(soundProvider.notifier).state = false;
    _nameController.clear();

    if (!mounted) return;
    _showSnack(deleteMessage);
    context.pop();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soundEnabled = ref.watch(soundProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Pressable(
                    onTap: () => context.pop(),
                    child: Text(
                      ref.tr('back'),
                      style: AppTheme.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ref.tr('settings'),
                    style: AppTheme.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 54),
                ],
              ),
              const SizedBox(height: 28),
              _SettingsSection(
                title: ref.tr('profile'),
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 16,
                    style: AppTheme.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      hintText: ref.tr('enter_name'),
                      prefixIcon: Icons.person,
                      errorText: _showNameError
                          ? ref.tr('name_required')
                          : null,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (!_showNameError && !_nameSaved) return;
                      setState(() {
                        _showNameError = false;
                        _nameSaved = false;
                      });
                    },
                    onSubmitted: (_) => _saveName(),
                  ),
                  const SizedBox(height: 12),
                  VoidActionButton(
                    onTap: _saveName,
                    label: _nameSaved ? ref.tr('saved') : ref.tr('save'),
                    icon: _nameSaved ? Icons.check : null,
                    backgroundColor: _nameSaved
                        ? AppTheme.primaryDim
                        : AppTheme.action,
                    foregroundColor: AppTheme.actionText,
                    accentColor: _nameSaved
                        ? AppTheme.primary
                        : AppTheme.primaryDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: ref.tr('preferences'),
                children: [
                  _SettingsTile(
                    icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
                    title: ref.tr('sound'),
                    trailing: Switch(
                      value: soundEnabled,
                      activeThumbColor: AppTheme.primary,
                      onChanged: _setSoundEnabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: ref.tr('data'),
                children: [
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    title: ref.tr('delete_data'),
                    subtitle: ref.tr('delete_data_short'),
                    danger: true,
                    onTap: _confirmDeleteData,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: ref.tr('about'),
                children: [
                  FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) {
                      final version = snapshot.hasData
                          ? 'v${snapshot.data!.version}'
                          : 'v...';
                      return _SettingsTile(
                        icon: Icons.info_outline,
                        title: ref.tr('version'),
                        trailing: Text(
                          version,
                          style: AppTheme.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTheme.inter(color: AppTheme.textTertiary, fontSize: 14),
      counterText: '',
      filled: true,
      fillColor: AppTheme.background,
      errorText: errorText,
      errorStyle: AppTheme.inter(color: AppTheme.wrong, fontSize: 12),
      prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary, size: 18),
      border: OutlineInputBorder(
        borderRadius: AppTheme.inputRadius,
        borderSide: const BorderSide(color: AppTheme.textTertiary, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.inputRadius,
        borderSide: const BorderSide(color: AppTheme.textTertiary, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.inputRadius,
        borderSide: const BorderSide(color: AppTheme.primary, width: 1),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(color: AppTheme.textTertiary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.inter(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.wrong : AppTheme.textPrimary;
    final content = Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: danger
                ? AppTheme.wrong.withValues(alpha: 0.12)
                : AppTheme.primaryDim,
            borderRadius: AppTheme.chipRadius,
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.inter(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AppTheme.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ] else if (onTap != null)
          Icon(Icons.chevron_right, color: color, size: 18),
      ],
    );

    if (onTap == null) return content;
    return Pressable(onTap: onTap, child: content);
  }
}
