import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/services/update_service.dart';

class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _hasUpdate = false;
  bool _dismissed = false;
  String? _latestVersion;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final service = UpdateService();
    final hasUpdate = await service.isUpdateAvailable();
    final version = await service.getLatestVersion();
    if (mounted) {
      setState(() {
        _hasUpdate = hasUpdate;
        _latestVersion = version;
      });
    }
  }

  void _download() {
    final platform = Platform.isWindows ? 'windows' : 'linux';
    final url = UpdateService().getDownloadUrl(platform);
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUpdate || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryDim,
        borderRadius: AppTheme.neutralRadius,
        border: Border.all(
          color: AppTheme.primaryDeep.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_outlined,
            color: AppTheme.primary,
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_latestVersion available',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _download,
            child: const Text(
              'Download',
              style: TextStyle(
                color: AppTheme.primaryDeep,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: Icon(
              Icons.close,
              color: AppTheme.textTertiary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}