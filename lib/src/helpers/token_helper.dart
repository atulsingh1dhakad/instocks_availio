class TokenHelper {
  /// returns expiry in milliseconds from "now" given secondsToLive
  static int computeExpiryFromNow({required int secondsToLive}) {
    return DateTime.now()
        .add(Duration(seconds: secondsToLive))
        .millisecondsSinceEpoch;
  }
}