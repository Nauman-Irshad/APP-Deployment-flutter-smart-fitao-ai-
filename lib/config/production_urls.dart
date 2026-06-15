/// Live URLs — Render, Vercel, CV, Cloudflare R2 (no local kurta/reel files in App).
class ProductionUrls {
  ProductionUrls._();

  static const String shop =
      'https://fyp-web-code-deployment-flea.vercel.app';

  static const String sizeApi = 'https://fyp-backend-hi10.onrender.com';

  static const String cvCamera =
      'https://qr-code-scan-computer-visionj-git-main-nauman-irshads-projects.vercel.app';

  static const String mediaCdn =
      'https://pub-f822ccb86a5c48d6817764a7e50f2c48.r2.dev';

  // —— 3D GLB on R2 (online only) ——
  static const String glbKurtaBlack =
      '$mediaCdn/landing%20page%20product/kurta/black%20kurta%20.glb';
  static const String glbKurtaBrown =
      '$mediaCdn/landing%20page%20product/kurta/brown%20kurta.glb';
  static const String glbKurtaSkyBlue =
      '$mediaCdn/landing%20page%20product/kurta/sky%20blue%20kurta.glb';
  static const String glbKurtaWhite =
      '$mediaCdn/landing%20page%20product/kurta/WHITE.glb';
  static const String glbShalwarBlack =
      '$mediaCdn/landing%20page%20product/shalwar/black%20shalwar%20kameez.glb';
  static const String glbShalwarBrown =
      '$mediaCdn/landing%20page%20product/shalwar/brown%201.glb';
  static const String glbShalwarWhite =
      '$mediaCdn/landing%20page%20product/shalwar/white%20shalwar%20kameez.glb';
  static const String glbShalwarNavy =
      '$mediaCdn/landing%20page%20product/shalwar/navy%20kurta%203d%20model.glb';

  // —— Reels on R2 (online only) ——
  static const String reel1 =
      '$mediaCdn/reels/6767035-uhd_2160_3840_25fps.mp4';
  static const String reel2 =
      '$mediaCdn/reels/Baju%20cutting%20mote%20ki%20gulami%20Dekhe%23tailor%20%23tailormaster%20%23darzi%20%23funnyvideo%20%23%20nice%20video%23tailor.mp4';
  static const String reel3 =
      '$mediaCdn/reels/ladies%20suit%20ka%20new%20design%20check%20Karen%20gale%20ka%23tailor%20%23funnyvideo%20%23darzi.mp4';
  static const String reel4 = '$mediaCdn/reels/videoplayback.mp4';
  static const String reel5 =
      '$mediaCdn/reels/%F0%9F%98%8Atrouser%20cutting%20and%20%23skdarzionlinestitching%20%23viral%20fashion%20%20%23shortsfeed%20%F0%9F%91%87%20(1).mp4';

  static String r2ObjectUrl(String objectKey) {
    final key = objectKey.trim().replaceAll('\\', '/');
    if (key.isEmpty) return mediaCdn;
    final encoded = key
        .split('/')
        .where((s) => s.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return '$mediaCdn/$encoded';
  }

  static const String stripePayment = String.fromEnvironment(
    'STRIPE_PAYMENT_BASE',
    defaultValue: 'https://smartfitao-stripe-api.onrender.com',
  );
}
