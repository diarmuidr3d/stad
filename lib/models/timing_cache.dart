import 'models.dart';

const CACHE_EXPIRY_SECONDS = 10;

class TimingCache {
  List<Timing> timings;
  DateTime cacheTime;
  TimingCache({required this.timings, DateTime? cacheTime})
      : this.cacheTime = cacheTime ?? DateTime.now();

  get isExpired {
    return cacheTime.difference(DateTime.now()).inSeconds >= 10;
  }

  @override
  String toString() {
    return "TimingCache-{cachetime: $cacheTime, expired: $isExpired, timings: $timings}";
  }
}
