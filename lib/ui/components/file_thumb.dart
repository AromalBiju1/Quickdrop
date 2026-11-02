import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/file_utils.dart';
import '../quickdrop_theme.dart';

class QuickDropLogo extends StatelessWidget {
  final double size;

  const QuickDropLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/quickdrop_logo.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'QuickDrop',
    );
  }
}

class FileThumb extends StatelessWidget {
  final String path;
  final double size;
  final double radius;

  const FileThumb({
    super.key,
    required this.path,
    this.size = 40,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = FileUtils.isImage(path);
    final file = File(path);
    final exists = file.existsSync();
    final visual = FileVisual.forPath(path);

    Widget child;
    if (isImage && exists) {
      child = Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, _, _) => _fallback(visual),
      );
    } else {
      child = _fallback(visual);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: visual.background,
        child: child,
      ),
    );
  }

  Widget _fallback(FileVisual visual) {
    return Center(
      child: Icon(
        visual.icon,
        color: visual.color,
        size: size * 0.48,
      ),
    );
  }
}

class FileVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const FileVisual(this.icon, this.color, this.background);

  static FileVisual forPath(String path) {
    if (FileUtils.isImage(path)) {
      return const FileVisual(
        Icons.image_outlined,
        QuickDropColors.emeraldDark,
        QuickDropColors.emeraldSoft,
      );
    }
    if (FileUtils.isVideo(path)) {
      return const FileVisual(
        Icons.play_circle_outline_rounded,
        QuickDropColors.violet,
        QuickDropColors.violetSoft,
      );
    }
    if (FileUtils.isAudio(path)) {
      return const FileVisual(
        Icons.graphic_eq_rounded,
        QuickDropColors.blue,
        QuickDropColors.blueSoft,
      );
    }
    switch (FileUtils.extension(path)) {
      case '.pdf':
        return const FileVisual(
          Icons.picture_as_pdf_outlined,
          QuickDropColors.rose,
          QuickDropColors.roseSoft,
        );
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return const FileVisual(
          Icons.folder_zip_outlined,
          QuickDropColors.amber,
          QuickDropColors.amberSoft,
        );
      case '.apk':
        return const FileVisual(
          Icons.android_rounded,
          QuickDropColors.emeraldDark,
          QuickDropColors.emeraldSoft,
        );
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
      case '.rtf':
        return const FileVisual(
          Icons.description_outlined,
          QuickDropColors.blue,
          QuickDropColors.blueSoft,
        );
      case '.xls':
      case '.xlsx':
      case '.csv':
        return const FileVisual(
          Icons.table_chart_outlined,
          QuickDropColors.emeraldDark,
          QuickDropColors.emeraldSoft,
        );
      case '.ppt':
      case '.pptx':
        return const FileVisual(
          Icons.slideshow_outlined,
          QuickDropColors.amber,
          QuickDropColors.amberSoft,
        );
      default:
        return const FileVisual(
          Icons.insert_drive_file_outlined,
          QuickDropColors.textMuted,
          QuickDropColors.surfaceSubtle,
        );
    }
  }
}

class SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionLabel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: QuickDropColors.textPrimary,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: QuickDropColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final Color? borderColor;
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    this.foreground = QuickDropColors.emeraldDark,
    this.background = QuickDropColors.emeraldSoft,
    this.borderColor,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? background,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const EmptyStateIcon({super.key, required this.icon, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: QuickDropColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: const BoxDecoration(
              color: QuickDropColors.emeraldSoft,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: BoxDecoration(
              color: QuickDropColors.emerald,
              shape: BoxShape.circle,
              boxShadow: QuickDropColors.cardShadow,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.22,
            ),
          ),
        ],
      ),
    );
  }
}
