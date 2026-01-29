import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/state/account_status_provider.dart';
import 'package:hello_flutter/state/native_gate.dart';
import 'package:hello_flutter/state/payment_provider.dart';
import 'package:hello_flutter/state/settings_controller.dart';
import 'package:hello_flutter/widgets/error_modal.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyPlusPage extends ConsumerWidget {
  const BuyPlusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountStatusProvider);
    final isUnlimitedPlus =
        account is PlusAccountStatus && account.bwConsumption == null;
    if (isUnlimitedPlus) {
      return ref
          .watch(paymentInfoProvider)
          .when(
            data: (info) => PlanLengthPage(
              title: 'Unlimited',
              description: 'Unlimited bandwidth',
              planType: PlanType.unlimited,
              pricePoints: info.rawPricePoints,
              paymentMethods: info.paymentMethods,
            ),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
          );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Plus'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ref
            .watch(paymentInfoProvider)
            .when(
              data: (info) {
                final unlimitedMonthly = _monthlyPrice(info.rawPricePoints);
                final basicMonthly = _monthlyPrice(info.basicPricePoints);
                return ListView(
                  children: [
                    _PlanCard(
                      title: 'Unlimited',
                      subtitle: 'Best for everyday usage',
                      icon: Icons.all_inclusive,
                      priceCents: unlimitedMonthly?.item2,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlanLengthPage(
                              title: 'Unlimited',
                              description: 'Unlimited bandwidth',
                              planType: PlanType.unlimited,
                              pricePoints: info.rawPricePoints,
                              paymentMethods: info.paymentMethods,
                            ),
                          ),
                        );
                      },
                      bullets: const [
                        _PlanBullet(
                          icon: Icons.all_inclusive,
                          label: 'Unlimited bandwidth',
                        ),
                        _PlanBullet(
                          icon: Icons.speed_outlined,
                          label: 'Remove speed limit',
                        ),
                        _PlanBullet(
                          icon: Icons.stars_outlined,
                          label: 'Access premium locations',
                        ),
                        _PlanBullet(
                          icon: Icons.shield_outlined,
                          label: 'More resilient connections',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      title: 'Basic',
                      subtitle: 'Best for occasional usage',
                      icon: Icons.speed,
                      priceCents: basicMonthly?.item2,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlanLengthPage(
                              title: 'Basic',
                              description: info.basicMbLimit > 0
                                  ? 'Bandwidth limit: ${info.basicMbLimit / 1000} GB per month'
                                  : 'Bandwidth limit: —',
                              planType: PlanType.basic,
                              pricePoints: info.basicPricePoints,
                              paymentMethods: info.paymentMethods,
                            ),
                          ),
                        );
                      },
                      bullets: [
                        _PlanBullet(
                          icon: Icons.speed,
                          label: info.basicMbLimit > 0
                              ? 'Bandwidth limit: ${info.basicMbLimit / 1000} GB per month'
                              : 'Bandwidth limit: —',
                        ),
                        const _PlanBullet(
                          icon: Icons.speed_outlined,
                          label: 'Remove speed limit',
                        ),
                        const _PlanBullet(
                          icon: Icons.stars_outlined,
                          label: 'Access premium locations',
                        ),
                        const _PlanBullet(
                          icon: Icons.shield_outlined,
                          label: 'More resilient connections',
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load prices: $error')),
            ),
      ),
    );
  }
}

Tuple2<int, int>? _monthlyPrice(List<Tuple2<int, int>> points) {
  if (points.isEmpty) return null;
  for (final point in points) {
    if (point.item1 == 30) {
      return point;
    }
  }
  return points.first;
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int? priceCents;
  final VoidCallback onTap;
  final List<_PlanBullet> bullets;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priceCents,
    required this.onTap,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = priceCents == null ? '—' : _formatPrice(priceCents!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('per month', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        for (final bullet in bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 22,
                                  child: Icon(
                                    bullet.icon,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    bullet.label,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBullet {
  final IconData icon;
  final String label;

  const _PlanBullet({required this.icon, required this.label});
}

String _formatPrice(int priceCents) {
  final euros = priceCents / 100.0;
  return '€${euros.toStringAsFixed(2)}';
}

enum PlanType { unlimited, basic }

class PlanLengthPage extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final PlanType planType;
  final List<Tuple2<int, int>> pricePoints;
  final List<String> paymentMethods;

  const PlanLengthPage({
    super.key,
    required this.title,
    required this.description,
    required this.planType,
    required this.pricePoints,
    required this.paymentMethods,
  });

  @override
  ConsumerState<PlanLengthPage> createState() => _PlanLengthPageState();
}

class _PlanLengthPageState extends ConsumerState<PlanLengthPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = widget.pricePoints;
    final secret = ref.watch(settingsProvider).secret ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description, style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (var index = 0; index < points.length; index++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        index == _selectedIndex
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text('${points[index].item1} days'),
                      trailing: Text(_formatPrice(points[index].item2)),
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.paymentMethods.isEmpty || secret.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaymentMethodsPage(
                              planType: widget.planType,
                              days: points[_selectedIndex].item1,
                              paymentMethods: widget.paymentMethods,
                            ),
                          ),
                        );
                      },
                child: const Text('Pay now'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: secret.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RedeemVoucherPage(),
                          ),
                        );
                      },
                child: const Text('Redeem voucher'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '— — —',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: secret.isEmpty
                    ? null
                    : () async {
                        final url = Uri.parse(
                          'https://geph.io/billing/login_secret?secret=$secret',
                        );
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                child: const Text('Other (crypto, buy vouchers, etc.)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodsPage extends ConsumerStatefulWidget {
  final PlanType planType;
  final int days;
  final List<String> paymentMethods;

  const PaymentMethodsPage({
    super.key,
    required this.planType,
    required this.days,
    required this.paymentMethods,
  });

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  bool _paying = false;
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose payment method'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promo code (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter promo code',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any discounts for this code will be applied at checkout!',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 26),
            if (_paying) const LinearProgressIndicator(),
            if (!_paying)
              Expanded(
                child: ListView.builder(
                  itemCount: widget.paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = widget.paymentMethods[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _startPayment(method),
                          child: Text(method),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPayment(String method) async {
    final secret = ref.read(settingsProvider).secret ?? '';
    if (secret.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => const ErrorModal(message: 'Missing account secret.'),
      );
      return;
    }
    setState(() => _paying = true);
    try {
      final gate = ref.read(nativeGateProvider);
      final rpcMethod = widget.planType == PlanType.basic
          ? 'create_basic_payment'
          : 'create_payment';
      final promo = _promoController.text.trim().toUpperCase();
      final methodArg = promo.isEmpty ? method : '$method+++$promo';
      final url = await gate.daemonRpc('broker_rpc', [
        rpcMethod,
        [secret, widget.days, methodArg],
      ]);
      if (url is String) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Failed to create payment.');
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorModal(message: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }
}

class RedeemVoucherPage extends ConsumerStatefulWidget {
  const RedeemVoucherPage({super.key});

  @override
  ConsumerState<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends ConsumerState<RedeemVoucherPage> {
  final TextEditingController _voucherController = TextEditingController();
  bool _redeeming = false;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem voucher'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _voucherController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter voucher code',
              ),
            ),
            const SizedBox(height: 12),
            if (_redeeming) const LinearProgressIndicator(),
            if (!_redeeming)
              FilledButton(
                onPressed: _voucherController.text.trim().isEmpty
                    ? null
                    : _redeem,
                child: const Text('Redeem'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _redeeming
                  ? null
                  : () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeem() async {
    final secret = ref.read(settingsProvider).secret ?? '';
    if (secret.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => const ErrorModal(message: 'Missing account secret.'),
      );
      return;
    }
    setState(() => _redeeming = true);
    try {
      final code = _voucherController.text.trim().toUpperCase();
      final gate = ref.read(nativeGateProvider);
      final daysAdded = await gate.daemonRpc('broker_rpc', [
        'redeem_voucher',
        [secret, code],
      ]);
      if (daysAdded is int && daysAdded > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voucher redeemed (+$daysAdded days)')),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Voucher invalid.');
      }
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => ErrorModal(message: error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _redeeming = false);
      }
    }
  }
}
