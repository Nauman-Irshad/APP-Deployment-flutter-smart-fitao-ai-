import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../2d_try_on_app/try_on_final_cart_screen.dart';
import '../2d_try_on_app/try_on_order_session.dart';
import 'checkout_order_completion.dart';
import 'stripe_pending_checkout.dart';
import 'stripe_url_clean.dart';

/// When Stripe redirects back with `?stripe_success=1`, finish the Firebase order.
class StripeReturnListener extends StatefulWidget {
  const StripeReturnListener({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<StripeReturnListener> createState() => _StripeReturnListenerState();
}

class _StripeReturnListenerState extends State<StripeReturnListener> {
  static bool _handledThisSession = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleStripeReturn());
    }
  }

  Future<void> _handleStripeReturn() async {
    if (_handledThisSession) return;

    final params = Uri.base.queryParameters;
    if (params.containsKey('stripe_cancel')) {
      _handledThisSession = true;
      stripStripeQueryFromUrl();
      await StripePendingCheckout.clear();
      if (!mounted) return;
      final ctx = _navContext();
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (params['stripe_success'] != '1') return;
    _handledThisSession = true;
    stripStripeQueryFromUrl();

    final pending = await StripePendingCheckout.load();
    if (pending == null) {
      if (!mounted) return;
      final ctx = _navContext();
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment received but no pending order found. Place the order again if needed.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final ctx = _navContext();
    if (ctx == null || !ctx.mounted) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Payment successful — placing your order...'),
        backgroundColor: Color(0xFF059669),
      ),
    );
    if (pending.category == 'TryOn+Tailor') {
      final sid = params['session_id'] ?? '';
      TryOnOrderSession.instance.paymentVerified = true;
      TryOnOrderSession.instance.lastPaymentWasDemoMock =
          sid.startsWith('mock_');
      TryOnOrderSession.instance.lastPaymentSessionId = sid;
      await StripePendingCheckout.clear();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Payment verified — PAID'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 5),
          ),
        );
        await TryOnFinalCartScreen.open(ctx);
      }
      return;
    }

    await CheckoutOrderCompletion.completeFromPending(ctx, pending);
  }

  BuildContext? _navContext() {
    final nav = widget.navigatorKey?.currentContext;
    if (nav != null && nav.mounted) return nav;
    return mounted ? context : null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
