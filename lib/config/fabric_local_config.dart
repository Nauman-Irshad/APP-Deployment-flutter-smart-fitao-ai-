/// Fabric images — **only** from `App/landing page product/fabric/` (bundled in APK / Edge assets).
/// Never use R2/CDN for fabric.
class FabricLocalConfig {
  FabricLocalConfig._();

  static const String fabricFolder = 'landing page product/fabric';

  static const List<String> catalogFiles = [
    'landing page product/fabric/fantansy latha.webp',
    'landing page product/fabric/gold.webp',
    'landing page product/fabric/shan e mughal latha.webp',
    'landing page product/fabric/sky blue.webp',
  ];

  static bool isFabricAssetPath(String? path) {
    final p = (path ?? '').trim().replaceAll('\\', '/');
    return p.contains('$fabricFolder/');
  }
}
