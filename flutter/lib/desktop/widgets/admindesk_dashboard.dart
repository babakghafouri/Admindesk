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
    final bg = dark ? const Color(0xFF181C28) : const Color(0xFFF5F7FB);
    final surface = dark ? const Color(0xFF242B39) : Colors.white;
    final border = dark ? Colors.white12 : const Color(0xFFE6EBF3);
    final ink = dark ? Colors.white : const Color(0xFF152945);
    final width = MediaQuery.of(context).size.width;
    final compact = width < 1020;
    final showPromo = width >= 950;

    return Directionality(
      textDirection: TextDirection.ltr, // Keep the reference's sidebar on left.
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [bg, const Color(0xFF1B3151), bg]
                : [const Color(0xFFF3F8FF), const Color(0xFFF8FBFF),
                   const Color(0xFFEAE8FF), const Color(0xFFE7F8FF)],
          ),
        ),
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
      width: width,
      decoration: BoxDecoration(
        color: surface.withOpacity(.76),
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
          _nav(Icons.contacts_outlined, 'مخاطبین', 3,
              compact, () => _openTab(3, 3)),
          _nav(Icons.star_border, 'دستگاه‌های ستاره‌دار', 4,
              compact, () => _openTab(4, 1)),
          _nav(Icons.settings_outlined, 'تنظیمات', 5, compact, _openSettings),
          const Spacer(),
        ],
      ),
    ));
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
        color: surface.withOpacity(.78),
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
                        child: Icon(slide.icon, size: 80, color: const Color(0xFF087BEE)),
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
