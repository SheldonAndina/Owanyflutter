import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

/// A lightweight wrapper around AlertDialog that respects OwanyTheme colors
/// and adapts background to dark/light modes.
class ThemedAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? actionsPadding;
  final ShapeBorder? shape;
  final Color? backgroundColor;

  const ThemedAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.actionsPadding,
    this.shape,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? OwanyTheme.surfaceColor(context);
    final shapeUsed = shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return AlertDialog(
      backgroundColor: bg,
      shape: shapeUsed,
      title: title,
      content: content,
      actions: actions,
      actionsPadding: actionsPadding,
    );
  }
}
