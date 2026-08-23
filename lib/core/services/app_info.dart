import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoData {
  final String appName;
  final String version;
  final String buildNumber;
  final String packageName;

  const AppInfoData({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });
}

final appInfoProvider = FutureProvider<AppInfoData>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppInfoData(
    appName: info.appName.isNotEmpty ? info.appName : 'BrewLine',
    version: info.version,
    buildNumber: info.buildNumber,
    packageName: info.packageName,
  );
});
