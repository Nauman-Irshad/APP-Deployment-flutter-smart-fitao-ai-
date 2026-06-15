import 'package:flutter/material.dart';

import '../payments/stripe_payment_config.dart';
import '../payments/stripe_payment_service.dart';
import '../payments/stripe_pending_checkout.dart';
import 'try_on_order_session.dart';
import 'try_on_theme.dart';

/// Product + tailor stitching + shipping → Stripe → payment verified.
class TryOnFinalCartScreen extends StatefulWidget {
  const TryOnFinalCartScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TryOnFinalCartScreen()),
    );
  }

  @override
  State<TryOnFinalCartScreen> createState() => _TryOnFinalCartScreenState();
}

class _TryOnFinalCartScreenState extends State<TryOnFinalCartScreen> {
  final _session = TryOnOrderSession.instance;
  bool _paying = false;
  int _payPercent = 0;
  String _payStep = '';
  String? _payError;

  String _rs(int n) =>
      'PKR ${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  void _setProgress(int percent, String step) {
    if (!mounted) return;
    setState(() {
      _payPercent = percent.clamp(0, 100);
      _payStep = step;
      if (percent < 100) _payError = null;
    });
  }

  Future<void> _payWithStripe() async {
    final tailor = _session.selectedTailor;
    if (tailor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a tailor from the list first')),
      );
      return;
    }
    if (_session.totalPkr < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order total must be greater than zero')),
      );
      return;
    }

    setState(() {
      _paying = true;
      _payError = null;
      _payPercent = 0;
      _payStep = 'Starting…';
    });

    try {
      _setProgress(10, 'Saving order for return from Stripe…');
      final userId = 'tryon_${DateTime.now().millisecondsSinceEpoch}';
      await StripePendingCheckout.save(
        StripePendingCheckout(
          userId: userId,
          productId: _session.garmentFileName.isNotEmpty
              ? _session.garmentFileName
              : 'tryon_product',
          productTitle:
              '${_session.garmentTitle} + ${tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name}',
          quantity: 1,
          unitPrice: _session.productPricePkr.toDouble(),
          totalPkr: _session.totalPkr,
          category: 'TryOn+Tailor',
          productImage: _session.garmentFileName,
          reducedPrice: _session.totalPkr.toDouble(),
        ),
      );

      _setProgress(20, 'Checking live Stripe mode (no demo)…');
      await StripePaymentService.ensureLiveCheckoutMode();
      _setProgress(30, 'Checking payment server ${StripePaymentConfig.baseUrl}…');
      await StripePaymentService.ensurePaymentServerReachable();

      _setProgress(45, 'Creating Stripe Checkout session…');
      final checkout = await StripePaymentService.createCheckoutSession(
        amountPkr: _session.totalPkr,
        productName: _session.garmentTitle,
        description:
            'Product ${_rs(_session.productPricePkr)} · Stitching ${_rs(_session.stitchingPkr)} · Shipping ${_rs(_session.shippingPkr)}',
        timeout: null,
      );

      _setProgress(85, 'Opening Stripe Checkout page…');
      await StripePaymentService.openCheckoutUrl(checkout.url);
      _setProgress(100, 'Complete payment on checkout.stripe.com (4242 4242 4242 4242)');
      _setProgress(100, 'Redirected to Stripe — complete payment in browser');
    } catch (e) {
      await StripePendingCheckout.clear();
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() {
          _payError = msg;
          _payStep = 'Failed';
          _payPercent = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailor = _session.selectedTailor;
    final tailorName =
        tailor == null ? '—' : (tailor.shopName.isNotEmpty ? tailor.shopName : tailor.name);
    final paid = _session.paymentVerified;
    final demoPaid = paid && _session.lastPaymentWasDemoMock;

    return Scaffold(
      backgroundColor: TryOnTheme.white,
      appBar: AppBar(
        backgroundColor: TryOnTheme.white,
        foregroundColor: TryOnTheme.brown,
        elevation: 0,
        title: Text('Final cart', style: TryOnTheme.heading(size: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (paid)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: demoPaid
                      ? const Color(0xFFfffbeb)
                      : const Color(0xFFf0fdf4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: demoPaid
                        ? const Color(0xFFd97706)
                        : const Color(0xFF059669),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      demoPaid ? Icons.info_outline : Icons.verified,
                      color: demoPaid
                          ? const Color(0xFFd97706)
                          : const Color(0xFF059669),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        demoPaid
                            ? 'PAID (demo only) — NOT in Stripe Dashboard.\n'
                                'Restart Stripe server (no MOCK=1), use VPN, pay with 4242… on checkout.stripe.com.'
                            : 'Payment verified — PAID (see Stripe Dashboard test payments)',
                        style: TryOnTheme.body(
                          size: 14,
                          weight: FontWeight.w700,
                          color: demoPaid
                              ? const Color(0xFFb45309)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (paid) const SizedBox(height: 16),
            Text('Order breakdown', style: TryOnTheme.heading(size: 16)),
            const SizedBox(height: 12),
            _line('Product', _session.garmentTitle, _rs(_session.productPricePkr)),
            _line('Tailor stitching', tailorName, _rs(_session.stitchingPkr)),
            _line('Shipping', 'Standard', _rs(_session.shippingPkr)),
            const Divider(height: 28),
            _line('Total', '', _rs(_session.totalPkr), bold: true),
            const SizedBox(height: 8),
            Text(
              _session.sizeSummary,
              style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted),
            ),
            if (_paying || _payError != null) ...[
              const SizedBox(height: 20),
              Text(
                _paying ? 'Payment progress' : 'Payment error',
                style: TryOnTheme.heading(size: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _paying ? _payPercent / 100 : 0,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFe5e7eb),
                  color: _payError != null
                      ? Colors.red
                      : const Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _paying ? '$_payPercent% — $_payStep' : _payStep,
                style: TryOnTheme.body(
                  size: 12,
                  color: _payError != null ? Colors.red.shade800 : TryOnTheme.brownMuted,
                ),
              ),
            ],
            if (_payError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFfef2f2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _payError!,
                  style: TryOnTheme.body(size: 12, color: Colors.red.shade900),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: paid || _paying ? null : _payWithStripe,
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock),
                label: Text(paid ? 'Already paid' : 'Pay with Stripe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (paid) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _paying
                    ? null
                    : () {
                        _session.resetPayment();
                        setState(() {
                          _payError = null;
                          _payPercent = 0;
                          _payStep = '';
                        });
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Pay again (new test)'),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Stripe Dashboard: https://dashboard.stripe.com/test/payments — only after real checkout.stripe.com pay.',
              textAlign: TextAlign.center,
              style: TryOnTheme.body(size: 11, color: TryOnTheme.brownMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String sub, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TryOnTheme.body(
                    size: bold ? 16 : 14,
                    weight: bold ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(sub, style: TryOnTheme.body(size: 12, color: TryOnTheme.brownMuted)),
              ],
            ),
          ),
          Text(
            value,
            style: TryOnTheme.body(
              size: bold ? 18 : 14,
              weight: FontWeight.w700,
              color: bold ? const Color(0xFF059669) : TryOnTheme.brown,
            ),
          ),
        ],
      ),
    );
  }
}
