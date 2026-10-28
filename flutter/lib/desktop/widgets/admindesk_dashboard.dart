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
                        child: const PromoCarousel(),
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

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));
    showToast(translate('Copied'));
  }

}
