import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/admindesk_theme.dart';

/// Navigation-only shell for the Windows home screen.
///
/// [onNavigate] delegates to the existing PeerTabPage controller, so the
/// sidebar never stores or invents devices and does not touch Rust/FFI.
class AdminDeskSideBar extends StatelessWidget {
  const AdminDeskSideBar({
    Key? key,
    required this.selectedMenu,
    required this.onNavigate,
    required this.onSettings,
    required this.versionLabel,
  }) : super(key: key);

  final int selectedMenu;
  final void Function(int menu, int peerTab) onNavigate;
  final VoidCallback onSettings;
  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AdminDeskColors.of(context);
    final width = AdminDeskMetrics.sidebarWidth;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: colors.sidebar,
          border: Border(
            left: BorderSide(color: colors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AdminDeskMetrics.spaceMd),
            _entry(context, Icons.home_outlined, 'خانه', 0,
                () => onNavigate(0, 0)),
            _entry(context, Icons.history_rounded, 'اتصالات اخیر', 2,
                () => onNavigate(2, 0)),
            _entry(context, Icons.star_border_rounded, 'دستگاه‌های ستاره‌دار', 4,
                () => onNavigate(4, 1)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AdminDeskMetrics.spaceSm,
                0,
                AdminDeskMetrics.spaceSm,
                AdminDeskMetrics.spaceMd,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminDeskMetrics.spaceXs,
                  vertical: AdminDeskMetrics.spaceMd,
                ),
                decoration: AdminDeskMetrics.cardDecoration(colors),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/icon.svg',
                      width: 72,
                      height: 72,
                    ),
                    const SizedBox(height: AdminDeskMetrics.spaceXs),
                    Text(
                      'AdminDesk',
                      textAlign: TextAlign.center,
                      style: AdminDeskTypography.title(colors),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Remote Access. Greater Control.',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: AdminDeskTypography.caption(colors).copyWith(
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: AdminDeskMetrics.spaceSm),
                    Text(
                      versionLabel,
                      textAlign: TextAlign.center,
                      style: AdminDeskTypography.caption(colors),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String label, int menu,
      VoidCallback onPressed) {
    final colors = AdminDeskColors.of(context);
    final active = selectedMenu == menu;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminDeskMetrics.spaceXs,
        vertical: 3,
      ),
      child: Material(
        color: active ? colors.primary : colors.sidebar,
        borderRadius: AdminDeskMetrics.controlRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AdminDeskMetrics.controlRadius,
          hoverColor: active ? colors.primaryHover : colors.hoverBackground,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: AdminDeskMetrics.spaceSm),
                Icon(
                  icon,
                  size: 20,
                  color: active ? colors.onPrimary : colors.textSecondary,
                ),
                const SizedBox(width: AdminDeskMetrics.spaceSm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminDeskTypography.body(colors).copyWith(
                      color: active ? colors.onPrimary : colors.textPrimary,
                      fontWeight: active
                          ? AdminDeskTypography.bold
                          : AdminDeskTypography.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
