import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
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
  int _promoPage = 0;
  final PageController _promoController = PageController();

  static const _blue = Color(0xFF087BEE);

  @override
  void dispose() {
    _requestedPeerTab.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _openTab(int menu, int peerTab) {
    // Respect hidden/disabled tabs rather than forcing a prohibited view.
    if (isOptionFixed(kOptionPeerTabIndex) ||
        !gFFI.peerTabModel.visibleEnabledOrderedIndexs.contains(peerTab)) {
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
    final bg = dark ? const Color(0xFF181C28) : const Color(0xFFE8F3FF);
    final surface = dark ? const Color(0xFF242B39) : const Color(0xFFF7FBFF);
    final border = dark ? Colors.white24 : const Color(0xFFD6E7FB);
    final ink = dark ? Colors.white : const Color(0xFF163559);
    final width = MediaQuery.of(context).size.width;
    final promoWidth = (width * .30).clamp(280.0, 435.0).toDouble();
    final deviceWidth = width < 1160 ? 210.0 : 242.0;

    // Windows dashboard: marketing on the left, real peer list in the center,
    // and the existing live server ID / password / install actions on the right.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [bg, const Color(0xFF202F48), bg]
                : [const Color(0xFFE8F4FF), const Color(0xFFF3F9FF),
                   const Color(0xFFE6F0FF)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _topBar(context, surface, border, ink),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: promoWidth,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 7, 10),
                            child: _marketingPanel(context, surface, border, ink),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(7, 12, 12, 10),
                            child: _connectionsPanel(context, surface, border, ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: deviceWidth,
              child: _devicePanel(context, surface, border, ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketingPanel(BuildContext context, Color surface, Color border,
      Color ink) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.withOpacity(.77),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.campaign_outlined, color: _blue, size: 22),
            const SizedBox(width: 7),
            Text('اخبار و خدمات AdminDesk',
                style: TextStyle(color: ink, fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _marketingThumb('دسترسی ایمن', Icons.shield_outlined,
                dark, border)),
            const SizedBox(width: 8),
            Expanded(child: _marketingThumb('پشتیبانی سریع',
                Icons.support_agent_rounded, dark, border)),
          ]),
          const SizedBox(height: 10),
          Expanded(child: _promo(context, ink)),
        ],
      ),
    );
  }

  Widget _marketingThumb(
      String label, IconData icon, bool dark, Color border) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: dark
            ? [const Color(0xFF213D65), const Color(0xFF1254A0)]
            : [const Color(0xFFF0F9FF), const Color(0xFFCCEAFF)]),
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SvgPicture.asset('assets/icon.svg', width: 30, height: 30),
            Icon(icon, color: _blue, size: 18),
          ]),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF125394),
                  fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _connectionsPanel(BuildContext context, Color surface, Color border,
      Color ink) {
    return Container(
      decoration: BoxDecoration(
        color: surface.withOpacity(.86),
        border: Border.all(color: Colors.white.withOpacity(.9)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: _blue, size: 23),
              const SizedBox(width: 9),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('اتصال‌های اخیر',
                    style: TextStyle(color: ink, fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const Text('Recent Sessions',
                    style: TextStyle(color: Color(0xFF527DA4), fontSize: 10)),
              ]),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ConnectionPage(
                  dashboardLayout: true,
                  requestedPeerTab: _requestedPeerTab,
                  peerTabNavigation: _peerNavigation(context, ink),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFF28B69A)),
              const SizedBox(width: 7),
              Text('مدیریت دستگاه‌ها', style:
                  TextStyle(fontSize: 10, color: ink.withOpacity(.7))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _peerNavigation(BuildContext context, Color ink) {
    final tabs = <({int id, IconData icon, String label})>[
      (id: 0, icon: Icons.access_time_filled, label: 'اتصالات اخیر'),
      (id: 1, icon: Icons.star, label: 'ستاره‌دارها'),
      (id: 2, icon: Icons.explore, label: 'شبکه محلی'),
      (id: 3, icon: Icons.contacts, label: 'مخاطبین'),
      (id: 4, icon: Icons.devices, label: 'دستگاه‌ها'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
      child: Row(children: [
        for (final tab in tabs)
          if (gFFI.peerTabModel.visibleEnabledOrderedIndexs.contains(tab.id))
            Tooltip(
              message: tab.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: () => _openTab(tab.id, tab.id),
                child: Container(
                  width: 39, height: 36,
                  decoration: BoxDecoration(
                    color: _selectedMenu == tab.id
                        ? _blue.withOpacity(.13) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: _selectedMenu == tab.id
                        ? const Border(bottom: BorderSide(color: _blue, width: 2))
                        : null,
                  ),
                  child: Icon(tab.icon, size: 20,
                      color: _selectedMenu == tab.id ? _blue
                          : ink.withOpacity(.55)),
                ),
              ),
            ),
        const Spacer(),
        IconButton(
          tooltip: 'تنظیمات',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.settings_outlined, color: _blue, size: 19),
          onPressed: _openSettings,
        ),
      ]),
    );
  }

  Widget _devicePanel(BuildContext context, Color surface, Color border,
      Color ink) {
    return Container(
      decoration: BoxDecoration(
        color: surface.withOpacity(.88),
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 17, 11, 17),
          child: Row(children: [
            Container(
              height: 42, width: 42,
              decoration: BoxDecoration(color: _blue,
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.shield_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 9),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('دستگاه من',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: ink)),
                Text('دسترسی به این دستگاه', style:
                    TextStyle(fontSize: 10, color: ink.withOpacity(.6))),
              ],
            )),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 12),
            child: Column(children: [
              ChangeNotifierProvider<ServerModel>.value(
                value: gFFI.serverModel,
                child: Consumer<ServerModel>(
                  builder: (context, model, _) {
                    final showOneTime = model.approveMode != 'click' &&
                        model.verificationMethod != kUsePermanentPassword;
                    return Column(children: [
                      _credentialCard(context, surface, border, ink,
                        title: 'شناسه دستگاه',
                        field: model.serverId,
                        icon: Icons.content_copy_outlined,
                        onPressed: () => _copy(model.serverId.text)),
                      const SizedBox(height: 10),
                      _credentialCard(context, surface, border, ink,
                        title: 'رمز عبور یک‌بارمصرف',
                        field: model.serverPasswd,
                        icon: showOneTime ? Icons.refresh : Icons.settings_outlined,
                        onPressed: showOneTime
                            ? () => bind.mainUpdateTemporaryPassword()
                            : () => DesktopSettingPage.switch2page(
                                SettingsTabKey.safety)),
                    ]);
                  },
                ),
              ),
              const SizedBox(height: 12),
              widget.notices,
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _topBar(BuildContext context, Color surface, Color border, Color ink) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: surface.withOpacity(.78),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icon.svg', width: 37, height: 37),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AdminDesk', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.w800, color: ink)),
              Text('دسترسی سریع و امن', style: TextStyle(fontSize: 9,
                  color: ink.withOpacity(.60))),
            ],
          ),
          const Spacer(),
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

  Widget _credentialCard(BuildContext context, Color surface, Color border,
      Color ink, {required String title, required TextEditingController field,
      required IconData icon, required VoidCallback onPressed}) {
    return Container(
      height: 102,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      decoration: BoxDecoration(
        color: surface.withOpacity(.78),
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
                    fontWeight: FontWeight.w800, color: ink))),
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
    const slides = <({String title, String subtitle, IconData icon,
        List<String> benefits})>[
      (title: 'مدیریت آسان\nدسترسی ایمن',
       subtitle: 'با Admin Desk به سیستم‌های خود متصل شوید',
       icon: Icons.security_rounded,
       benefits: ['اتصال سریع و پایدار', 'امنیت بالا',
                  'سازگار با سیستم‌عامل‌های مختلف']),
      (title: 'همیشه متصل',
       subtitle: 'ارتباط حرفه‌ای با رایانه‌های خود از هر جا',
       icon: Icons.computer_rounded,
       benefits: ['پشتیبانی از ویندوز و اندروید', 'اتصال از راه دور',
                  'مدیریت سادهٔ دستگاه‌ها']),
      (title: 'دسترسی کنترل‌شده',
       subtitle: 'ابزارهایی که برای پشتیبانی نیاز دارید',
       icon: Icons.verified_user_rounded,
       benefits: ['رمز یک‌بارمصرف', 'انتقال فایل در اتصال مجاز',
                  'دسترسی با تأیید کاربر']),
      (title: 'Admin Desk',
       subtitle: 'تجربه‌ای روان و یکپارچه برای پشتیبانی',
       icon: Icons.support_agent_rounded,
       benefits: ['رابط فارسی خوانا', 'مدیریت اتصال‌ها',
                  'کنترل حرفه‌ای از راه دور']),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFDDEEFF), Color(0xFFB8DCFF), Color(0xFFD9EAFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.8)),
        boxShadow: [BoxShadow(color: const Color(0xFF80B9F1).withOpacity(.17),
            blurRadius: 24, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _promoController,
              itemCount: slides.length,
              onPageChanged: (index) => setState(() => _promoPage = index),
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${index + 1}/4',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 11,
                              color: Color(0xFF42699E), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      Text(slide.title, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF153B6A),
                            fontSize: 20, height: 1.45, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text(slide.subtitle, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF28547D),
                            fontSize: 11, height: 1.6)),
                      const SizedBox(height: 24),
                      ...slide.benefits.map((benefit) => _benefit(benefit)),
                      const SizedBox(height: 20),
                      Container(
                        height: 122,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.30),
                          border: Border.all(color: Colors.white.withOpacity(.65)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/icon.svg',
                                width: 62, height: 62),
                            const SizedBox(height: 6),
                            const Text('AdminDesk',
                                style: TextStyle(fontWeight: FontWeight.w800,
                                    color: Color(0xFF15518F), fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 86,
            padding: const EdgeInsets.fromLTRB(9, 6, 9, 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.88),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                  tooltip: 'قبلی',
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _promoPage > 0 ? () => _promoController.previousPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut) : null,
                ),
                Row(children: List.generate(slides.length, (index) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _promoPage == index ? 16 : 6, height: 6,
                    decoration: BoxDecoration(
                      color: _promoPage == index
                          ? const Color(0xFF087BEE) : const Color(0xFFB4C9DA),
                      borderRadius: BorderRadius.circular(6)),
                  ))),
                IconButton(
                  tooltip: 'بعدی',
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _promoPage < slides.length - 1
                      ? () => _promoController.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOut) : null,
                ),
              ]),
              SizedBox(
                height: 27,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _promoController.animateToPage(
                      (_promoPage + 1) % slides.length,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _blue, foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                  child: const Text('اطلاعات بیشتر',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
            ]),
          ),
        ],
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
