import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics listelerinin oturum/attempt sonrası yenilenmesi.
final analyticsRefreshProvider =
    NotifierProvider<AnalyticsRefreshNotifier, int>(
  AnalyticsRefreshNotifier.new,
);

class AnalyticsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
