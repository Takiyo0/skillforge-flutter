class AssetUrls {
  AssetUrls._();

  static const String baseCdnUrl = String.fromEnvironment(
    'BASE_CDN_URL',
    defaultValue: 'https://cdn-sf-apac.takiyo.us',
  );

  static String? cdnUrl(String? s3Key) {
    if (s3Key == null || s3Key.trim().isEmpty) return null;
    final key = s3Key.trim();
    if (key.startsWith('http://') || key.startsWith('https://')) return key;
    return '$baseCdnUrl/$key';
  }

  static String? courseThumbnailUrl(String? thumbnailS3Key) {
    return cdnUrl(thumbnailS3Key);
  }

  static String? avatarUrl(String? avatarS3Key) {
    return cdnUrl(avatarS3Key);
  }

  static String dicebearAvatarUrl(String seed) {
    final cleanSeed = seed.trim().isEmpty ? 'skillforge-user' : seed.trim();
    return Uri.https('api.dicebear.com', '/7.x/avataaars/svg', {
      'seed': cleanSeed,
    }).toString();
  }

  static bool isSvgUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    return path.endsWith('.svg') || path.contains('/svg');
  }
}
