import 'dart:async';

import 'package:flutter/material.dart';

import '../quickdrop_theme.dart';

/// The visual weight of a top notice.
enum TopNoticeTone { success, info, warning, error }

/// A transient in-app notice rendered above the whole app.
///
/// Notices replace each other instead of stacking, so rapid transfers produce
/// one calm banner rather than a queue of overlapping messages.
@immutable
class TopNotice {
  final String message;
  final String? detail;
  final IconData? icon;
  final TopNoticeTone tone;

  /// How long the notice stays visible. [Duration.zero] keeps it until it is
  /// replaced or dismissed.
  final Duration duration;

  final String? actionLabel;
  final VoidCallback? onAction;

  const TopNotice({
    required this.message,
    this.detail,
    this.icon,
    this.tone = TopNoticeTone.success,
    this.duration = const Duration(seconds: 4),
    this.actionLabel,
    this.onAction,
  });
}

/// Owns the current notice and its auto-dismiss timer.
///
/// Mounted once near the root of the widget tree through [TopNoticeScope] and
/// [TopNoticeHost], so screens, dialogs and popup menus all share it.
class TopNoticeCenter extends ChangeNotifier {
  TopNotice? _current;
  Timer? _timer;
  int _revision = 0;

  TopNotice? get current => _current;

  /// Changes every time a notice is shown, giving the host a stable animation
  /// key even when the same message is repeated.
  int get revision => _revision;

  void show(TopNotice notice) {
    _timer?.cancel();
    _current = notice;
    _revision++;
    notifyListeners();

    if (notice.duration > Duration.zero) {
      _timer = Timer(notice.duration, dismiss);
    }
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_current == null) return;
    _current = null;
    _revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Makes the app-wide [TopNoticeCenter] available to any descendant context.
class TopNoticeScope extends InheritedNotifier<TopNoticeCenter> {
  final TopNoticeCenter controller;

  const TopNoticeScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  static TopNoticeCenter? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TopNoticeScope>()?.controller;

  static TopNoticeCenter of(BuildContext context) {
    final center = maybeOf(context);
    assert(center != null, 'No TopNoticeScope found in this context.');
    return center!;
  }
}

/// Shows a top notice from any context below [TopNoticeScope].
///
/// Returns false when no scope is mounted, which keeps call sites safe in
/// isolated widget tests.
bool showTopNotice(BuildContext context, TopNotice notice) {
  final center = TopNoticeScope.maybeOf(context);
  if (center == null) return false;
  center.show(notice);
  return true;
}

/// Paints [TopNoticeCenter.current] above [child], including above dialogs.
class TopNoticeHost extends StatelessWidget {
  final TopNoticeCenter controller;
  final Widget child;

  const TopNoticeHost({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final notice = controller.current;
        return Stack(
          children: [
            child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: IgnorePointer(
                  ignoring: notice == null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, -0.25),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: notice == null
                        ? const SizedBox.shrink(
                            key: ValueKey('top-notice-empty'),
                          )
                        : _TopNoticeCard(
                            key: ValueKey(controller.revision),
                            notice: notice,
                            onDismiss: controller.dismiss,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopNoticeCard extends StatelessWidget {
  final TopNotice notice;
  final VoidCallback onDismiss;

  const _TopNoticeCard({
    super.key,
    required this.notice,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    final palette = _paletteFor(notice.tone, p);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                  boxShadow: p.raisedShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: palette.soft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        notice.icon ?? palette.icon,
                        size: 19,
                        color: palette.strong,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium!.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                          if (notice.detail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              notice.detail!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall!.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (notice.actionLabel != null) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () {
                          onDismiss();
                          notice.onAction?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: palette.strong,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: context.text.labelLarge!.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        child: Text(notice.actionLabel!),
                      ),
                    ],
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: p.textFaint,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticePalette {
  final Color strong;
  final Color soft;
  final Color border;
  final IconData icon;

  const _NoticePalette({
    required this.strong,
    required this.soft,
    required this.border,
    required this.icon,
  });
}

_NoticePalette _paletteFor(TopNoticeTone tone, QuickDropPalette p) {
  switch (tone) {
    case TopNoticeTone.success:
      return _NoticePalette(
        strong: p.emeraldDark,
        soft: p.emeraldSoft,
        border: p.emeraldBorder,
        icon: Icons.check_circle_rounded,
      );
    case TopNoticeTone.info:
      return _NoticePalette(
        strong: p.blue,
        soft: p.blueSoft,
        border: p.blue.withValues(alpha: 0.35),
        icon: Icons.info_rounded,
      );
    case TopNoticeTone.warning:
      return _NoticePalette(
        strong: p.amber,
        soft: p.amberSoft,
        border: p.amberBorder,
        icon: Icons.warning_amber_rounded,
      );
    case TopNoticeTone.error:
      return _NoticePalette(
        strong: p.roseDark,
        soft: p.roseSoft,
        border: p.roseBorder,
        icon: Icons.error_outline_rounded,
      );
  }
}
