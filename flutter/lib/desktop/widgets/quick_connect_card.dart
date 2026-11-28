import 'package:flutter/material.dart';

import '../theme/admindesk_theme.dart';

/// Windows-only visual wrapper around the original ConnectionPage input.
///
/// [connectFields] is the existing RawAutocomplete/ID controller, favorite
/// actions, connect callback, history, and advanced connection menu. This
/// widget does not store peer IDs or implement a parallel connection flow.
class QuickConnectCard extends StatelessWidget {
  const QuickConnectCard({
    Key? key,
    required this.connectFields,
  }) : super(key: key);

  final Widget connectFields;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return SizedBox(
      height: 152,
      child: Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminDeskMetrics.spaceSm,
          vertical: AdminDeskMetrics.spaceXs,
        ),
        decoration: AdminDeskMetrics.cardDecoration(c),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اتصال سریع',
              style: AdminDeskTypography.heading(c),
            ),
            const SizedBox(height: 2),
            Text(
              'برای اتصال به دستگاه دیگر، شناسه آن را وارد کنید',
              style: AdminDeskTypography.caption(c),
            ),
            const SizedBox(height: AdminDeskMetrics.spaceSm),
            connectFields,
          ],
        ),
      ),
      ),
    );
  }
}
