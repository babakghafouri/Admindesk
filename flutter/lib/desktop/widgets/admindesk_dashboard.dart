import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:provider/provider.dart';

/// Presentation-only desktop dashboard. Connection, server state and peer
/// operations are intentionally delegated to the existing RustDesk widgets.
class AdminDeskDashboard extends StatefulWidget {
  final Widget notices;

  const AdminDeskDashboard({Key? key, required this.notices}) : super(key: key);

  @override
  State<AdminDeskDashboard> createState() => _AdminDeskDashboardState();
}

class _AdminDeskDashboardState extends State<AdminDeskDashboard> {
  final ValueNotifier<int?> _requestedPeerTab = ValueNotifier<int?>(null);
  int _selectedMenu = 0;

  static const _blue = Color(0xFF087BEE);

  @override
  void dispose() {
    _requestedPeerTab.dispose();
    super.dispose();
  }

  void _openTab(int menu, int peerTab) {
    // Respect hidden/disabled tabs rather than forcing a prohibited view.
    if (!gFFI.peerTabModel.visibleEnabledOrderedIndexs.contains(peerTab)) {
      showToast(translate('Unavailable'));
      return;
    }
    setState(() => _selectedMenu = menu);
    // A repeated sidebar click must still refocus the requested device tab.
    if (_requestedPeerTab.value == peerTab) {
      _requestedPeerTab.value = null;
    }
    _requestedPeerTab.value = peerTab;
  }

  void _openSettings() {
    if (!bind.isDisableSettings()) {
      DesktopTabPage.onAddSetting();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF181C28) : const Color(0xFFF5F7FB);
    final surface = dark ? const Color(0xFF242B39) : Colors.white;
    final border = dark ? Colors.white12 : const Color(0xFFE6EBF3);
    final ink = dark ? Colors.white : const Color(0xFF152945);
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1020;
    final showPromo = width >= 1250;

    return Directionality(
      textDirection: TextDirection.ltr, // Keep the reference's sidebar on left.
      child: ColoredBox(
        color: bg,
        child: Row(
          children: [
            _sidebar(context, compact, surface, border, ink),
            Expanded(
              child: Column(
                children: [
                  _topBar(context, surface, border, ink),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                compact ? 12 : 18, 14, showPromo ? 10 : 18, 10),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('اتصال سریع',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: ink)),
                                  const SizedBox(height: 2),
                                  Text('برای اتصال، شناسه دستگاه مقصد را وارد کنید',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: ink.withOpacity(0.6))),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ConnectionPage(
                                      dashboardLayout: true,
                                      requestedPeerTab: _requestedPeerTab,
                                      identityCards: bind.isOutgoingOnly()
                                          ? null
                                          : ChangeNotifierProvider<ServerModel>.value(
                                              value: gFFI.serverModel,
                                              child: Consumer<ServerModel>(
                                                builder: (context, model, child) =>
                                                    _credentialsRow(
                                                        context, model, surface, border, ink),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (!showPromo) widget.notices,
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (showPromo)
                          SizedBox(
                            width: 240,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 14, 14, 10),
                              child: Column(
                                children: [
                                  Expanded(child: _promo(context, ink)),
                                  widget.notices,
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar(BuildContext context, bool compact, Color surface,
      Color border, Color ink) {
    final width = compact ? 66.0 : 203.0;
    final labelStyle = TextStyle(
        color: ink, fontSize: 12, fontWeight: FontWeight.w600);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surface,
        border: Border(right: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icon.svg', width: 38, height: 38),
              if (!compact) ...[
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Desk',
                          maxLines: 1, style: labelStyle.copyWith(fontSize: 17)),
                      Text('اتصال امن، مدیریت آسان',
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 9, color: ink.withOpacity(.65))),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          _nav(Icons.home_outlined, 'خانه', 0, compact, () => _openTab(0, 0)),
          _nav(Icons.desktop_windows_outlined, 'دستگاه‌های من', 1,
              compact, () => _openTab(1, 0)),
          _nav(Icons.history, 'اتصالات اخیر', 2,
              compact, () => _openTab(2, 0)),
          _nav(Icons.contacts_outlined, 'مخاطبین', 3,
              compact, () => _openTab(3, 3)),
          _nav(Icons.star_border, 'دستگاه‌های ستاره‌دار', 4,
              compact, () => _openTab(4, 1)),
          _nav(Icons.settings_outlined, 'تنظیمات', 5, compact, _openSettings),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10 : const Color(0xFFF5F8FD),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SvgPicture.asset('assets/icon.svg', width: 46, height: 46),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  Text('Admin Desk', style: labelStyle.copyWith(fontSize: 17)),
                  Text('Remote Access · Greater Control',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 8, color: ink.withOpacity(.7))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(IconData icon, String label, int index,
      bool compact, VoidCallback onTap) {
    final active = index == _selectedMenu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Tooltip(
        message: label,
        child: Material(
          color: active ? _blue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 38,
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  if (!compact) const SizedBox(width: 10),
                  Icon(icon,
                      size: 20,
                      color: active
                          ? Colors.white : Theme.of(context).iconTheme.color),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700 : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyMedium?.color)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, Color surface, Color border, Color ink) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _themeButton(
            Icons.wb_sunny_outlined, 'روشن', !dark,
            () => MyTheme.changeDarkMode(ThemeMode.light), ink),
          const SizedBox(width: 4),
          _themeButton(
            Icons.dark_mode_outlined, 'تاریک', dark,
            () => MyTheme.changeDarkMode(ThemeMode.dark), ink),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'تنظیمات',
            icon: Icon(Icons.settings_outlined, size: 20, color: ink),
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _themeButton(IconData icon, String label, bool active,
      VoidCallback onPressed, Color ink) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? _blue.withOpacity(.13) : Colors.transparent,
            border: active ? Border.all(color: _blue.withOpacity(.5)) : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: active ? _blue : ink),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(
                  fontSize: 11, color: active ? _blue : ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _credentialsRow(BuildContext context, ServerModel model,
      Color surface, Color border, Color ink) {
    final showOneTime = model.approveMode != 'click' &&
        model.verificationMethod != kUsePermanentPassword;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(child: _credentialCard(
            context, surface, border, ink,
            title: 'شناسه دستگاه شما',
            field: model.serverId,
            icon: Icons.content_copy_outlined,
            onPressed: () => _copy(model.serverId.text),
          )),
          const SizedBox(width: 10),
          Expanded(child: _credentialCard(
            context, surface, border, ink,
            title: 'رمز عبور یکبار مصرف',
            field: model.serverPasswd,
            icon: showOneTime ? Icons.refresh : Icons.settings_outlined,
            onPressed: showOneTime
                ? () => bind.mainUpdateTemporaryPassword()
                : () => DesktopSettingPage.switch2page(SettingsTabKey.safety),
          )),
        ],
      ),
    );
  }

  Widget _credentialCard(BuildContext context, Color surface, Color border,
      Color ink, {required String title, required TextEditingController field,
      required IconData icon, required VoidCallback onPressed}) {
    return Container(
      height: 102,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: ink))),
            IconButton(
              tooltip: title,
              onPressed: onPressed,
              icon: Icon(icon, color: _blue, size: 19),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ]),
          Expanded(
            child: TextField(
              controller: field,
              readOnly: true,
              showCursor: false,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero),
              style: const TextStyle(
                color: _blue, fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    showToast(translate('Copied'));
  }

  Widget _promo(BuildContext context, Color ink) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9EDFF), Color(0xFFA8D3FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(13),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('مدیریت آسان\nدسترسی ایمن',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF133458),
                    fontSize: 23, height: 1.25,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('با Admin Desk به دستگاه‌های خود متصل شوید',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF244763), fontSize: 11)),
            const SizedBox(height: 18),
            _benefit('اتصال سریع و آسان'),
            _benefit('امنیت بالا'),
            _benefit('سازگار با دستگاه‌های مختلف'),
            const Spacer(),
            SvgPicture.asset('assets/icon.svg', width: 105, height: 105),
            const SizedBox(height: 12),
            Text('Admin Desk',
                style: TextStyle(color: ink,
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _benefit(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      const Icon(Icons.check_circle, color: Color(0xFF10B96C), size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF153759)))),
    ]),
  );
}
