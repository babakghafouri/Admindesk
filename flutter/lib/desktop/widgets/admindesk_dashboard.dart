import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/theme/admindesk_theme.dart';
import 'package:flutter_hbb/desktop/widgets/admindesk_credentials.dart';
import 'package:flutter_hbb/desktop/widgets/admindesk_sidebar.dart';
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
    final colors = AdminDeskColors.of(context);
    final width = MediaQuery.of(context).size.width;
    // Keep live device credentials visible at 900 px; hide promotions first.
    final showPromo = width >= 1250;
    final promoWidth = (width * .22).clamp(270.0, 355.0).toDouble();

    // The existing top-level DesktopTab owns the window titlebar and its
    // minimize/maximize/close actions. Do not render a second fake titlebar.
    // Only rearrange presentation: optional promo, peers, live ID/OTP,
    // then the RTL navigation sidebar on the far right.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: colors.canvas,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showPromo)
                    SizedBox(
                      width: promoWidth,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
                        child: _marketingPanel(context, colors.surface,
                            colors.border, colors.textPrimary),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        showPromo ? 6 : 12, 12, 8, 10),
                      child: _connectionsPanel(context, colors.surface,
                          colors.border, colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            AdminDeskSideBar(
              selectedMenu: _selectedMenu,
              versionLabel: version.isEmpty ? 'AdminDesk' : 'نسخه $version',
              onNavigate: _openTab,
              onSettings: _openSettings,
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
    final colors = AdminDeskColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AdminDeskMetrics.spaceSm),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: AdminDeskMetrics.cardRadius,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: ConnectionPage(
                dashboardLayout: true,
                requestedPeerTab: _requestedPeerTab,
                // Preserve the existing ConnectionPage controller, autofill,
                // onConnect, and the real ServerModel ID/OTP controllers.
                identityCards: ChangeNotifierProvider<ServerModel>.value(
                  value: gFFI.serverModel,
                  child: Consumer<ServerModel>(
                    builder: (context, model, _) {
                      final canRefresh = model.approveMode != 'click' &&
                          model.verificationMethod != kUsePermanentPassword;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AdminDeskMetrics.spaceSm,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = <Widget>[
                              IdCard(
                                controller: model.serverId,
                                onCopy: () => _copy(model.serverId.text),
                                onOpenSecuritySettings: () =>
                                    DesktopSettingPage.switch2page(
                                        SettingsTabKey.safety),
                              ),
                              OtpCard(
                                controller: model.serverPasswd,
                                canRefresh: canRefresh,
                                onRefresh: () => bind.mainUpdateTemporaryPassword(),
                                onOpenSecuritySettings: () =>
                                    DesktopSettingPage.switch2page(
                                        SettingsTabKey.safety),
                              ),
                            ];
                            // Avoid card overflow on narrow Windows windows.
                            if (constraints.maxWidth < 470) {
                              return Column(
                                children: [
                                  cards.first,
                                  const SizedBox(height: AdminDeskMetrics.spaceXs),
                                  cards.last,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: cards.first),
                                const SizedBox(width: AdminDeskMetrics.spaceSm),
                                Expanded(child: cards.last),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                peerTabNavigation: _peerNavigation(context, ink),
              ),
            ),
            widget.notices,
          ],
        ),
      ),
    );
  }

  int _menuForPeerTab(int peerTab) {
    switch (peerTab) {
      case 0:
        return 2; // Recent sessions
      case 1:
        return 4; // Starred devices
      case 3:
        return 3; // Contacts
      case 4:
        return 1; // My devices
      default:
        return 1;
    }
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
                onTap: () => _openTab(_menuForPeerTab(tab.id), tab.id),
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
