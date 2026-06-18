import '../Order-Tracking-System/services/app_backend.dart';
import '../Order-Tracking-System/tracking.dart' show OrderStatus;
import 'tailor_chat_service.dart';
import 'seller_chat_service.dart';

/// Red badge counts for tailor bottom nav (orders + messages).
class RoleOrderBadges {
  RoleOrderBadges._();

  static bool _needsTailorOrderAction(OrderStatus s) {
    return s == OrderStatus.shippedToTailor ||
        s == OrderStatus.tailorDelivered ||
        s == OrderStatus.tailorStitched;
  }

  static bool _needsSellerAttention(OrderStatus s) {
    return s == OrderStatus.withSeller ||
        s == OrderStatus.pending ||
        s == OrderStatus.shippedToTailor;
  }

  /// New / active tailor orders (badge on Orders tab only).
  static Stream<int> tailorPendingCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return AppBackend.instance.streamOrdersForTailor(uid).map(
          (orders) =>
              orders.where((o) => _needsTailorOrderAction(o.status)).length,
        );
  }

  static Stream<int> sellerPendingCount(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return AppBackend.instance.streamOrdersForSeller(uid).map(
          (orders) => orders.where((o) => _needsSellerAttention(o.status)).length,
        );
  }

  static Stream<int> tailorUnreadMessages(String uid) {
    return TailorChatService.watchTailorUnreadTotal(uid);
  }

  static Stream<int> sellerUnreadMessages(String uid) {
    return SellerChatService.watchSellerUnreadTotal(uid);
  }
}
