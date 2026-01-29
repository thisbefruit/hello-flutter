import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

import 'native_gate.dart';

class PaymentInfo {
  final List<Tuple2<int, int>> rawPricePoints;
  final List<Tuple2<int, int>> basicPricePoints;
  final int basicMbLimit;
  final List<String> paymentMethods;

  const PaymentInfo({
    required this.rawPricePoints,
    required this.basicPricePoints,
    required this.basicMbLimit,
    required this.paymentMethods,
  });
}

final paymentInfoProvider = FutureProvider<PaymentInfo>((ref) async {
  final gate = ref.read(nativeGateProvider);

  final rawPrice = await gate.daemonRpc('broker_rpc', ['raw_price_points']);
  final basicPrice = await gate.daemonRpc('broker_rpc', ['basic_price_points']);
  final basicLimit = await gate.daemonRpc('broker_rpc', ['basic_mb_limit']);
  final paymentMethods = await gate.daemonRpc('broker_rpc', ['payment_methods']);

  return PaymentInfo(
    rawPricePoints: _parsePricePoints(rawPrice),
    basicPricePoints: _parsePricePoints(basicPrice),
    basicMbLimit: basicLimit is int ? basicLimit : 0,
    paymentMethods: _parseStringList(paymentMethods),
  );
});

List<Tuple2<int, int>> _parsePricePoints(Object? raw) {
  if (raw is! List) return const [];
  final points = <Tuple2<int, int>>[];
  for (final entry in raw) {
    if (entry is Tuple2<int, int>) {
      points.add(entry);
      continue;
    }
    if (entry is! List || entry.length < 2) continue;
    final a = entry[0];
    final b = entry[1];
    if (a is int && b is int) {
      points.add(Tuple2(a, b));
    } else if (a is num && b is num) {
      points.add(Tuple2(a.toInt(), b.toInt()));
    }
  }
  return points;
}

List<String> _parseStringList(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final entry in raw)
      if (entry is String) entry,
  ];
}
