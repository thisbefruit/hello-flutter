import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_flutter/pages/buy_plus.dart';
import 'package:hello_flutter/pages/home_page.dart';
import 'package:hello_flutter/state/account_status_provider.dart';
import 'package:hello_flutter/state/native_gate.dart';

class AccountInfoSection extends ConsumerWidget {
  const AccountInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountStatusProvider);
    String usageLabel = 'Unlimited Usage';
    double usageProgress = 1.0;
    String expiryDateLabel = 'No expiry';
    String remainingDaysLabel = 'Remaining days: —';
    if (account is PlusAccountStatus && account.bwConsumption != null) {
      final bw = account.bwConsumption!;
      final limitMb = bw.mbLimit;
      final usedMb = bw.mbUsed;
      final remainingMb = (limitMb - usedMb).clamp(0, limitMb);
      final remainingGb = remainingMb / 1000;
      final limitGb = limitMb / 1000;
      usageLabel =
          '${remainingGb.toStringAsFixed(1)}GB / ${limitGb.toStringAsFixed(1)}GB Remaining';
      usageProgress = limitMb == 0 ? 0.0 : remainingMb / limitMb;
    }
    if (account is PlusAccountStatus) {
      final expiry = account.expiry;
      final remainingDays = expiry.difference(DateTime.now()).inDays;
      final year = expiry.year.toString().padLeft(4, '0');
      final month = expiry.month.toString().padLeft(2, '0');
      final day = expiry.day.toString().padLeft(2, '0');
      expiryDateLabel = '$year-$month-$day';
      remainingDaysLabel = 'Remaining days: ${remainingDays.clamp(0, 9999)}';
    }
    final actionLabel = account is PlusAccountStatus ? 'Extend' : 'Buy Plus';

    return RoundedPaddedCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 30,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(expiryDateLabel), Text(remainingDaysLabel)],
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BuyPlusPage()),
                  );
                },
                child: Text(actionLabel),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            children: [
              Icon(
                Icons.electric_meter_outlined,
                size: 30,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usageLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    LinearProgressIndicator(
                      value: usageProgress,
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
