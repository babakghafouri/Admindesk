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
        icon: Icon(Icons.copy_outlined, size: 19, color: c.textSecondary),
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
            child: Text('تنظیم',
              style: AdminDeskTypography.caption(c).copyWith(
                color: c.primary, fontWeight: AdminDeskTypography.semibold)),
          ),
        ],
      ),
    );
  }
}

/// Only displays the password and calls the existing password-refresh action.
class OtpCard extends StatelessWidget {
  const OtpCard({
    Key? key,
    required this.controller,
    required this.canRefresh,
    required this.onRefresh,
    required this.onOpenSecuritySettings,
  }) : super(key: key);

  final TextEditingController controller;
  final bool canRefresh;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenSecuritySettings;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return _CredentialSurface(
      title: 'رمز عبور یک‌بارمصرف',
      controller: controller,
      action: IconButton(
        tooltip: canRefresh ? 'تولید رمز جدید' : 'تنظیمات رمز',
        onPressed: canRefresh ? onRefresh : onOpenSecuritySettings,
        icon: Icon(
          canRefresh ? Icons.refresh : Icons.settings_outlined,
          size: 20, color: c.textSecondary,
        ),
      ),
      footer: Row(
        children: [
          Icon(Icons.schedule_outlined, color: c.textSecondary, size: 17),
          const SizedBox(width: AdminDeskMetrics.spaceXs),
          Expanded(
            child: Text(
              canRefresh ? 'رمز موقت فعال' : 'مدیریت رمز از تنظیمات امنیتی',
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
  });

  final String title;
  final TextEditingController controller;
  final Widget action;
  final Widget footer;

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
              builder: (context, _) => Align(
                alignment: Alignment.centerRight,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    controller.text,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: AdminDeskTypography.identity(c),
                  ),
                ),
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
