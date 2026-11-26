import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/theme/admindesk_theme.dart';
import 'package:flutter_hbb/desktop/widgets/admindesk_credentials.dart';
import 'package:flutter_hbb/desktop/widgets/admindesk_sidebar.dart';
import 'package:flutter_hbb/desktop/widgets/promo_carousel.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _adminDeskVersion = '';
  int _selectedMenu = 2;
  bool _promoCollapsed = false;

  @override
  void initState() {
    super.initState();
    _selectedMenu = _menuForPeerTab(gFFI.peerTabModel.currentTab);
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _adminDeskVersion = info.version);
    });
  }

  @override
  void dispose() {
    _requestedPeerTab.dispose();
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
    final promoWidth = _promoCollapsed
        ? 60.0
        : (width * .22).clamp(270.0, 355.0).toDouble();

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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      width: promoWidth,
                      child: Padding(
                        padding: _promoCollapsed
                             ? const EdgeInsets.symmetric(vertical: 10, horizontal: 0)
                             : const EdgeInsets.fromLTRB(12, 12, 6, 10),
                        child: _promoCollapsed
                            ? Container(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: AdminDeskMetrics.cardRadius,
                                  border: Border.all(color: colors.border),
                                  boxShadow: AdminDeskMetrics.cardShadow(colors),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 5),
                                    Tooltip(
                                      message: 'بازکردن پنل تبلیغات',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          onTap: () => setState(
                                              () => _promoCollapsed = false),
                                          child: SizedBox(
                                            width: 42,
                                            height: 38,
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              size: 27,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF11A8E8), Color(0xFF0758C9)],
                                        ),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'FD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'FaraDNS',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: AdminDeskTypography.caption(colors).copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: Center(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            '185.255.208.208',
                                            textDirection: TextDirection.ltr,
                                            maxLines: 1,
                                            style: AdminDeskTypography.caption(colors).copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: .35,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Tooltip(
                                      message: 'جمع کردن پنل تبلیغات',
                                      child: IconButton(
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints.tightFor(
                                          width: 30,
                                          height: 30,
                                        ),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => setState(
                                            () => _promoCollapsed = true),
                                        icon: Icon(
                                          Icons.chevron_left_rounded,
                                          size: 19,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Expanded(child: PromoCarousel()),
                                ],
                              ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        showPromo ? 6 : 12, 12, 2, 10),
                      child: _connectionsPanel(context, colors.surface,
                          colors.border, colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            AdminDeskSideBar(
              selectedMenu: _selectedMenu,
              versionLabel: _adminDeskVersion.isEmpty
                  ? 'AdminDesk'
                  : 'نسخه $_adminDeskVersion',
              onNavigate: _openTab,
              onSettings: _openSettings,
            ),
          ],
        ),
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
                      return LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = <Widget>[
                              FutureBuilder<String>(
                                future: bind.mainGetCommon(key: 'permanent-password-set'),
                                builder: (context, snapshot) => IdCard(
                                unattendedEnabled: !snapshot.hasData ? null : model.approveMode == 'password' && model.verificationMethod != kUseTemporaryPassword && snapshot.data == 'true',
                                controller: model.serverId,
                                onCopy: () => _copy(model.serverId.text),
                                onOpenSecuritySettings: () =>
                                    DesktopSettingPage.switch2page(
                                        SettingsTabKey.safety),
                              )),
                              OtpCard(
                                controller: model.serverPasswd,
                                canRefresh: canRefresh,
                                onRefresh: () => bind.mainUpdateTemporaryPassword(),
                                onCopy: () => _copy(model.serverPasswd.text),
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
                        );
                    },
                  ),
                ),
                onPeerTabChanged: (tab) {
                  if (mounted) {
                    setState(() => _selectedMenu = _menuForPeerTab(tab));
                  }
                },
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
      case 1:
      case 2:
      case 3:
      case 4:
        return peerTab;
      default:
        return 0;
    }
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    showToast('کپی شد');
  }

}
