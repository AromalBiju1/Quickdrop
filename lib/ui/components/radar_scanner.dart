import 'package:flutter/material.dart';
import '../quickdrop_theme.dart';

class RadarScanner extends StatefulWidget {
  final bool isScanning;
  final int discoveredCount;
  final VoidCallback? onRefresh;

  const RadarScanner({
    super.key,
    required this.isScanning,
    required this.discoveredCount,
    this.onRefresh,
  });

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: QuickDropColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QuickDropColors.border),
      ),
      child: Row(
        children: [
          // Animated Pulse Ring
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isScanning)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 48 * _controller.value,
                        height: 48 * _controller.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: QuickDropColors.cyan
                                .withValues(alpha: 1.0 - _controller.value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: QuickDropColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering,
                    color: QuickDropColors.cyan,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.discoveredCount > 0
                          ? '${widget.discoveredCount} Device${widget.discoveredCount > 1 ? "s" : ""} Online'
                          : 'Searching Local Wi-Fi...',
                      style: const TextStyle(
                        color: QuickDropColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.discoveredCount > 0
                            ? QuickDropColors.emerald
                            : QuickDropColors.amber,
                        boxShadow: [
                          BoxShadow(
                            color: (widget.discoveredCount > 0
                                    ? QuickDropColors.emerald
                                    : QuickDropColors.amber)
                                .withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Zero-config UDP discovery on port 53317',
                  style: TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: QuickDropColors.textSecondary),
              tooltip: 'Broadcast beacon',
              onPressed: widget.onRefresh,
            ),
        ],
      ),
    );
  }
}
