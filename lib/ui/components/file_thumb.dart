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
    final visual = FileVisual.forPath(path, context.qd);

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
      child: Icon(visual.icon, color: visual.color, size: size * 0.48),
    );
  }
}

class FileVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const FileVisual(this.icon, this.color, this.background);

  static FileVisual forPath(String path, QuickDropPalette palette) {
    if (FileUtils.isImage(path)) {
      return FileVisual(
        Icons.image_outlined,
        palette.emeraldDark,
        palette.emeraldSoft,
      );
    }
    if (FileUtils.isVideo(path)) {
      return FileVisual(
        Icons.play_circle_outline_rounded,
        palette.violet,
        palette.violetSoft,
      );
    }
    if (FileUtils.isAudio(path)) {
      return FileVisual(
        Icons.graphic_eq_rounded,
        palette.blue,
        palette.blueSoft,
      );
    }
    switch (FileUtils.extension(path)) {
      case '.pdf':
        return FileVisual(
          Icons.picture_as_pdf_outlined,
          palette.rose,
          palette.roseSoft,
        );
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return FileVisual(
          Icons.folder_zip_outlined,
          palette.amber,
          palette.amberSoft,
        );
      case '.apk':
        return FileVisual(
          Icons.android_rounded,
          palette.emeraldDark,
          palette.emeraldSoft,
        );
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
      case '.rtf':
        return FileVisual(
          Icons.description_outlined,
          palette.blue,
          palette.blueSoft,
        );
      case '.xls':
      case '.xlsx':
      case '.csv':
        return FileVisual(
          Icons.table_chart_outlined,
          palette.emeraldDark,
          palette.emeraldSoft,
        );
      case '.ppt':
      case '.pptx':
        return FileVisual(
          Icons.slideshow_outlined,
          palette.amber,
          palette.amberSoft,
        );
      default:
        return FileVisual(
          Icons.insert_drive_file_outlined,
          palette.textMuted,
          palette.surfaceSubtle,
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
                style: TextStyle(
                  color: context.qd.textPrimary,
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
                  style: TextStyle(
                    color: context.qd.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;
  final bool dot;

  const StatusPill({
    super.key,
    required this.label,
    this.foreground,
    this.background,
    this.borderColor,
    this.dot = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.qd;
    final fg = foreground ?? p.emeraldDark;
    final bg = background ?? p.emeraldSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? bg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
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
            decoration: BoxDecoration(
              color: context.qd.surfaceMuted,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: context.qd.emeraldSoft,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: BoxDecoration(
              color: context.qd.emerald,
              shape: BoxShape.circle,
              boxShadow: context.qd.cardShadow,
            ),
            child: Icon(icon, color: context.qd.onAccent, size: size * 0.22),
          ),
        ],
      ),
    );
  }
}
