import 'package:flutter/material.dart';

import '../theme/admindesk_theme.dart';

/// A read-only view of the original ServerModel ID controller.
class IdCard extends StatelessWidget {
  const IdCard({
    Key? key,
    required this.controller,
    required this.onCopy,
    required this.onOpenSecuritySettings,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback onCopy;
  final VoidCallback? onOpenSecuritySettings;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return _CredentialSurface(
      title: 'شناسه دستگاه شما',
      action: IconButton(
        tooltip: 'کپی شناسه',
        onPressed: onCopy,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.content_copy_outlined, size: 19, color: c.textSecondary),
      ),
      controller: controller,
      footer: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: c.primary, size: 17),
          const SizedBox(width: AdminDeskMetrics.spaceXs),
          Expanded(
            child: Text('دسترسی بدون نظارت',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AdminDeskTypography.caption(c)),
          ),
          TextButton(
            onPressed: onOpenSecuritySettings,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text('تنظیم',
              style: AdminDeskTypography.caption(c).copyWith(
                color: c.primary, fontWeight: AdminDeskTypography.semibold)),
          ),
        ],
      ),
    );
  }
}

/// Displays the temporary password masked by default, with explicit reveal,
/// copy, and refresh actions. The controller remains owned by ServerModel.
class OtpCard extends StatefulWidget {
  const OtpCard({
    Key? key,
    required this.controller,
    required this.canRefresh,
    required this.onRefresh,
    required this.onCopy,
    required this.onOpenSecuritySettings,
  }) : super(key: key);

  final TextEditingController controller;
  final bool canRefresh;
  final VoidCallback onRefresh;
  final VoidCallback onCopy;
  final VoidCallback? onOpenSecuritySettings;

  @override
  State<OtpCard> createState() => _OtpCardState();
}

class _OtpCardState extends State<OtpCard> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return _CredentialSurface(
      title: 'رمز عبور یک‌بارمصرف',
      controller: widget.controller,
      obscureText: _obscurePassword,
      centerValue: true,
      action: const SizedBox.shrink(),
      valueActions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'کپی رمز عبور',
            onPressed: widget.onCopy,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.copy_rounded, size: 17, color: c.textSecondary),
          ),
          IconButton(
            tooltip: _obscurePassword ? 'نمایش رمز' : 'مخفی‌کردن رمز',
            onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 19,
              color: c.textSecondary,
            ),
          ),
          IconButton(
            tooltip: widget.canRefresh ? 'تولید رمز جدید' : 'تنظیمات رمز',
            onPressed: widget.canRefresh
                ? widget.onRefresh
                : widget.onOpenSecuritySettings,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(
              widget.canRefresh ? Icons.refresh : Icons.settings_outlined,
              size: 20,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
      footer: Row(
        children: [
          Icon(Icons.schedule_outlined, color: c.textSecondary, size: 17),
          const SizedBox(width: AdminDeskMetrics.spaceXs),
          Expanded(
            child: Text(
              widget.canRefresh ? 'رمز موقت فعال' : 'مدیریت رمز از تنظیمات امنیتی',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AdminDeskTypography.caption(c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card surface; keeps the live controller and Latin ID/password text.
class _CredentialSurface extends StatelessWidget {
  const _CredentialSurface({
    required this.title,
    required this.controller,
    required this.action,
    required this.footer,
    this.obscureText = false,
    this.centerValue = true,
    this.valueActions,
  });

  final String title;
  final TextEditingController controller;
  final Widget action;
  final Widget footer;
  final bool obscureText;
  final bool centerValue;
  final Widget? valueActions;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return Container(
      height: 136,
      padding: const EdgeInsets.symmetric(
        horizontal: AdminDeskMetrics.spaceMd,
        vertical: AdminDeskMetrics.spaceXs,
      ),
      decoration: AdminDeskMetrics.cardDecoration(c),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminDeskTypography.title(c).copyWith(fontSize: 13)),
                ),
                action,
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: SelectableText(
                        obscureText && controller.text.isNotEmpty
                            ? '••••••••'
                            : controller.text,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: AdminDeskTypography.identity(c),
                      ),
                    ),
                  ),
                  if (valueActions != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(child: valueActions!),
                    ),
                ],
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: footer,
          ),
        ],
      ),
    );
  }
}
