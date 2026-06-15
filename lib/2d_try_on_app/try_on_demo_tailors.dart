import '../Order-Tracking-System/services/app_backend.dart';

/// Shown when Firestore has no tailors yet (demo for 2D try-on flow).
List<AppUserProfile> demoTryOnTailors() => [
      AppUserProfile(
        uid: 'demo_tailor_1',
        name: 'Ahmed Khan',
        email: 'ahmed@smartfitao.demo',
        role: 'tailor',
        shopName: 'Royal Stitch Lahore',
        address: 'Gulberg, Lahore',
        available: true,
        stitchingRate: 2500,
      ),
      AppUserProfile(
        uid: 'demo_tailor_2',
        name: 'Hassan Ali',
        email: 'hassan@smartfitao.demo',
        role: 'tailor',
        shopName: 'Elite Tailors Karachi',
        address: 'DHA Phase 5, Karachi',
        available: true,
        stitchingRate: 3200,
      ),
      AppUserProfile(
        uid: 'demo_tailor_3',
        name: 'Usman Raza',
        email: 'usman@smartfitao.demo',
        role: 'tailor',
        shopName: 'SmartFitao Master Tailor',
        address: 'F-7, Islamabad',
        available: true,
        stitchingRate: 2800,
      ),
      AppUserProfile(
        uid: 'demo_tailor_4',
        name: 'Bilal Sheikh',
        email: 'bilal@smartfitao.demo',
        role: 'tailor',
        shopName: 'Heritage Kurta House',
        address: 'Model Town, Lahore',
        available: true,
        stitchingRate: 2100,
      ),
    ];
