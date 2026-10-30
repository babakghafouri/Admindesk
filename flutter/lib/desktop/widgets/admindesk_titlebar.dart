import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/state_model.dart';
import '../theme/admindesk_theme.dart';

/// Brand in the existing Windows drag-to-move titlebar.
/// Window minimize / maximize / close stay in RustDesk's WindowActionPanel,
/// which already implements the correct tray and prevent-close semantics.
class AdminDeskTitleBrand extends StatelessWidget {
  const AdminDeskTitleBrand({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AdminDeskColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icon.svg', width: 32, height: 32),
        const SizedBox(width: AdminDeskMetrics.spaceXs),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AdminDesk',
              style: AdminDeskTypography.title(colors).copyWith(
                fontSize: 17,
                height: 1.1,
              ),
            ),
            Text(
              'اتصال امن، مدیریت آسان',
              style: AdminDeskTypography.caption(colors).copyWith(
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Only a view over MyTheme's existing local preference mechanism.
class AdminDeskThemeToggle extends StatelessWidget {
  const AdminDeskThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AdminDeskColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.selectedBackground,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mode(context, colors, Icons.light_mode_outlined,
              'روشن', !isDark, ThemeMode.light),
          _mode(context, colors, Icons.dark_mode_outlined,
              'تاریک', isDark, ThemeMode.dark),
        ],
      ),
    );
  }

  Widget _mode(BuildContext context, AdminDeskColors colors, IconData icon,
      String label, bool active, ThemeMode mode) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => MyTheme.changeDarkMode(mode),
        child: Container(
          decoration: BoxDecoration(
            color: active ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: active ? Border.all(color: colors.border) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Row(
            children: [
              Icon(icon, size: 15,
                  color: active ? colors.primary : colors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: AdminDeskTypography.caption(colors).copyWith(
                fontSize: 10,
                fontWeight: active
                    ? AdminDeskTypography.bold
                    : AdminDeskTypography.medium,
                color: active ? colors.primary : colors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// App actions placed immediately before the existing native-behavior
/// simulated Windows controls in DesktopTab's WindowActionPanel.
class AdminDeskTitleActions extends StatelessWidget {
  const AdminDeskTitleActions({
    Key? key,
    required this.onSettings,
    required this.settingsEnabled,
  }) : super(key: key);

  final VoidCallback onSettings;
  final bool settingsEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = AdminDeskColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminDeskServerHealth(),
        const SizedBox(width: AdminDeskMetrics.spaceXs),
        const AdminDeskThemeToggle(),
        const SizedBox(width: AdminDeskMetrics.spaceXs),
        Obx(() {
          final hasUpdate = stateGlobal.updateUrl.value.isNotEmpty;
          return PopupMenuButton<int>(
            tooltip: 'اعلان‌ها',
            padding: EdgeInsets.zero,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded,
                    size: 20, color: colors.textPrimary),
                if (hasUpdate)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: colors.notification,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem<int>(
                value: 1,
                enabled: hasUpdate && settingsEnabled,
                child: Text(
                  hasUpdate
                      ? 'به‌روزرسانی جدید در دسترس است'
                      : 'اعلان تازه‌ای وجود ندارد',
                  style: AdminDeskTypography.body(colors),
                ),
              ),
            ],
            onSelected: (_) => onSettings(),
          );
        }),
        IconButton(
          tooltip: 'تنظیمات',
          constraints: const BoxConstraints(minWidth: 34, minHeight: 32),
          padding: EdgeInsets.zero,
          onPressed: settingsEnabled ? onSettings : null,
          icon: Icon(Icons.settings_outlined,
              size: 19, color: colors.textPrimary),
        ),
      ],
    );
  }
}


/// Live TCP reachability/latency indicator for the AdminDesk rendezvous server.
/// This measures the TCP handshake to port 21116 (not ICMP echo ping).
class AdminDeskServerHealth extends StatefulWidget {
  const AdminDeskServerHealth({Key? key}) : super(key: key);

  @override
  State<AdminDeskServerHealth> createState() => _AdminDeskServerHealthState();
}

class _AdminDeskServerHealthState extends State<AdminDeskServerHealth> {
  static const String _host = 'desk.admin98.ir';
  static const int _port = 21116;
  Timer? _timer;
  int? _latencyMs;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    final watch = Stopwatch()..start();
    int? result;
    Socket? socket;
    try {
      socket = await Socket.connect(
        _host,
        _port,
        timeout: const Duration(seconds: 3),
      );
      watch.stop();
      result = watch.elapsedMilliseconds;
    } catch (_) {
      result = null;
    } finally {
      socket?.destroy();
      _checking = false;
    }
    if (mounted) setState(() => _latencyMs = result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminDeskColors.of(context);
    final ms = _latencyMs;
    final Color signalColor;
    final String quality;
    if (ms == null) {
      signalColor = const Color(0xFFE34D4D);
      quality = 'قطع ارتباط';
    } else if (ms < 50) {
      signalColor = const Color(0xFF16A765);
      quality = 'عالی';
    } else if (ms < 100) {
      signalColor = const Color(0xFF79BF45);
      quality = 'خوب';
    } else if (ms < 200) {
      signalColor = const Color(0xFFE6B91E);
      quality = 'متوسط';
    } else if (ms <= 400) {
      signalColor = const Color(0xFFEF8B25);
      quality = 'ضعیف';
    } else {
      signalColor = const Color(0xFFE34D4D);
      quality = 'بسیار ضعیف';
    }

    // One compact icon only; its color communicates server reachability
    // and TCP handshake latency. Tap to run an immediate check.
    return Tooltip(
      message: ms == null
          ? 'سرور $_host در دسترس نیست'
          : 'سرور $_host\nکیفیت: $quality\nزمان اتصال TCP: $ms ms',
      child: IconButton(
        tooltip: 'وضعیت اتصال به سرور',
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        padding: EdgeInsets.zero,
        onPressed: _check,
        icon: Icon(
          Icons.wifi_tethering_rounded,
          size: 21,
          color: signalColor,
        ),
      ),
    );
  }}
