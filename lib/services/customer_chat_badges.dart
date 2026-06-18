import 'dart:async';

import '../services/seller_chat_service.dart';
import '../services/tailor_chat_service.dart';

/// Red badge on customer Chat tab (messages from tailor or seller).
class CustomerChatBadges {
  CustomerChatBadges._();

  static Stream<int> unreadTotal(String customerId) {
    if (customerId.isEmpty) return Stream.value(0);

    final controller = StreamController<int>.broadcast();
    StreamSubscription<int>? tailorSub;
    StreamSubscription<int>? sellerSub;
    var tailor = 0;
    var seller = 0;

    void emit() {
      if (!controller.isClosed) controller.add(tailor + seller);
    }

    controller.onListen = () {
      tailorSub = TailorChatService.watchCustomerUnreadTotal(customerId).listen(
        (v) {
          tailor = v;
          emit();
        },
      );
      sellerSub = SellerChatService.watchCustomerUnreadTotal(customerId).listen(
        (v) {
          seller = v;
          emit();
        },
      );
    };

    controller.onCancel = () async {
      await tailorSub?.cancel();
      await sellerSub?.cancel();
    };

    return controller.stream;
  }
}
