import 'package:flutter/widgets.dart';

/// One place for motion policy, so every new animation respects the OS
/// "reduce motion" setting.
class QuickDropMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
