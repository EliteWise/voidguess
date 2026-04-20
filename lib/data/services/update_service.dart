import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String _repoOwner = 'EliteWise';
  static const String _repoName = 'voidguess';

  Future<String?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tag_name'] as String?; // ex: "v1.0.0"
      }
    } catch (_) {}
    return null;
  }

  Future<bool> isUpdateAvailable() async {
    try {
      final latestVersion = await getLatestVersion();
      if (latestVersion == null) return false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = 'v${packageInfo.version}';

      return latestVersion != currentVersion;
    } catch (_) {
      return false;
    }
  }

  String getDownloadUrl(String platform) {
    return 'https://github.com/$_repoOwner/$_repoName/releases/latest/download/voidguess-$platform.zip';
  }
}