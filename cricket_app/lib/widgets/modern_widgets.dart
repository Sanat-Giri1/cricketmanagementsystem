import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ---------------------------------------------------------------------------
/// Shared component library.
/// Screens only ever import from here for cards, buttons, inputs, dropdowns,
/// dialogs, empty/loading states, and page headers — this is what keeps every
/// screen in the app visually identical. No business logic lives here.
/// ---------------------------------------------------------------------------

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  ({Color bg, Color fg, Color? border}) _colors() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (bg: _hovered ? AppColors.primaryDark : AppColors.primary, fg: Colors.white, border: null);
      case AppButtonVariant.secondary:
        return (bg: _hovered ? AppColors.accent.withValues(alpha: 0.85) : AppColors.accent, fg: Colors.white, border: null);
      case AppButtonVariant.outline:
        return (bg: _hovered ? AppColors.primaryTint : Colors.transparent, fg: AppColors.primary, border: AppColors.primary);
      case AppButtonVariant.danger:
        return (bg: _hovered ? const Color(0xFFDC2626) : AppColors.error, fg: Colors.white, border: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors();
    final borderColor = c.border;
    final disabled = widget.onPressed == null || widget.loading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        width: widget.fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: disabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: disabled ? c.bg.withValues(alpha: 0.5) : c.bg,
            foregroundColor: c.fg,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: borderColor != null ? BorderSide(color: borderColor, width: 1.4) : BorderSide.none,
            ),
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Rounded, shadowed content container used for every section/card on screen.
class AppSectionCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool hoverElevate;
  final VoidCallback? onTap;

  const AppSectionCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.hoverElevate = false,
    this.onTap,
  });

  @override
  State<AppSectionCard> createState() => _AppSectionCardState();
}

class _AppSectionCardState extends State<AppSectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: (widget.hoverElevate && _hovered) ? AppShadows.elevated : AppShadows.soft,
      ),
      transform: (widget.hoverElevate && _hovered)
          ? (Matrix4.identity()..translate(0.0, -2.0))
          : Matrix4.identity(),
      // Any child (e.g. a ListTile) needs its own Material ancestor to paint
      // ink splashes/backgrounds correctly — the colored decoration above
      // would otherwise hide them. Clipped to match the rounded corners.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null && !widget.hoverElevate) return content;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(onTap: widget.onTap, child: content),
    );
  }
}

/// Page title + subtitle, used at the top of every screen's scroll body.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppPageHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h1),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: AppText.body.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Friendly empty state with icon, title, subtitle — used whenever a list has
/// no data instead of a bare "no data" text.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppText.h3, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: AppText.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered loading state with a message, used inside FutureBuilder waiting
/// branches in place of a bare spinner.
class AppLoadingState extends StatelessWidget {
  final String? message;
  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Inline error card, used in place of bare "Error: ..." text.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.errorTint, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong', style: AppText.h3),
            const SizedBox(height: 6),
            Text(message, style: AppText.caption, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry, variant: AppButtonVariant.outline),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small colored status pill, e.g. "out" / "not out" / match status labels.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  const AppBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Styled text field with consistent labeling, spacing, and optional icon.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final IconData? icon;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppText.body,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textSecondary) : null,
        ),
      ),
    );
  }
}

/// Styled dropdown matching the input field look — wraps DropdownButtonFormField.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        style: AppText.body,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.textSecondary) : null,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Standard modal wrapper for add/edit forms across the app.
Future<T?> showAppFormDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppText.h2),
      content: SizedBox(width: 420, child: content),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: actions,
    ),
  );
}

/// Standard destructive-confirmation dialog (delete records, end actions, etc).
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppText.h2),
      content: Text(message, style: AppText.body.copyWith(color: AppColors.textSecondary)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        AppButton(
          label: confirmLabel,
          variant: AppButtonVariant.danger,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Consistent toast/snackbar helper so every screen surfaces feedback the
/// same way (success = green accent, error = red).
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? AppColors.error : AppColors.textPrimary,
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}

/// Stat card for dashboards — icon, label, value, optional trend accent.
class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      hoverElevate: true,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppText.h2),
                const SizedBox(height: 2),
                Text(label, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}