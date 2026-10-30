import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/peer_card.dart';
import 'package:flutter_hbb/common/widgets/peers_view.dart';
import 'package:flutter_hbb/models/peer_model.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../theme/admindesk_theme.dart';

/// Limits the new table layout to the Windows dashboard without changing
/// other RustDesk peer views, their loaders, or their online query lifecycle.
class DevicesTableScope extends InheritedWidget {
  const DevicesTableScope({
    Key? key,
    required this.enabled,
    required Widget child,
  }) : super(key: key, child: child);

  final bool enabled;

  static bool enabledOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DevicesTableScope>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(DevicesTableScope oldWidget) =>
      enabled != oldWidget.enabled;
}

/// Header controls for switching native peer tabs and the native search query.
class DevicesTableTabs extends StatelessWidget {
  const DevicesTableTabs({
    Key? key,
    required this.currentTab,
    required this.availableTabs,
    required this.onTabSelected,
    required this.onRefresh,
    this.showNavigation = true,
  }) : super(key: key);

  final int currentTab;
  final List<int> availableTabs;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onRefresh;
  final bool showNavigation;

  static const _tabs = <({int index, String title, IconData icon})>[
    (index: 4, title: 'دستگاه‌های من', icon: Icons.desktop_windows_outlined),
    (index: 0, title: 'اتصالات اخیر', icon: Icons.history_rounded),
    (index: 3, title: 'مخاطبین', icon: Icons.contacts_outlined),
    (index: 1, title: 'دستگاه‌های ستاره‌دار', icon: Icons.star_border_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 710;
      final tabs = <Widget>[
        for (final t in _tabs)
          if (availableTabs.contains(t.index))
            _tab(context, c, t.index, t.title, t.icon),
        if (availableTabs.contains(2))
          PopupMenuButton<int>(
            tooltip: 'سایر دستگاه‌ها',
            onSelected: onTabSelected,
            itemBuilder: (_) => [
              const PopupMenuItem<int>(
                value: 2,
                child: Text('شبکه محلی'),
              ),
            ],
            icon: Icon(Icons.more_horiz_rounded, color: c.textSecondary),
          ),
      ];
      final search = _search(c);
      return Container(
        padding: const EdgeInsets.all(AdminDeskMetrics.spaceXs),
        decoration: AdminDeskMetrics.cardDecoration(c),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: !showNavigation
              ? Row(children: [Expanded(child: search), _refresh(c)])
              : compact
              ? Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: tabs),
                    ),
                    const SizedBox(height: AdminDeskMetrics.spaceXs),
                    Row(children: [
                      Expanded(child: search),
                      _refresh(c),
                    ]),
                  ],
                )
              : Row(children: [
                  ...tabs,
                  const SizedBox(width: AdminDeskMetrics.spaceSm),
                  Expanded(child: search),
                  _refresh(c),
                ]),
        ),
      );
    });
  }

  Widget _tab(BuildContext context, AdminDeskColors c, int index,
      String title, IconData icon) {
    final selected = index == currentTab;
    return Tooltip(
      message: title,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Material(
          color: selected ? c.selectedBackground : c.surface,
          borderRadius: AdminDeskMetrics.controlRadius,
          child: InkWell(
            onTap: () => onTabSelected(index),
            borderRadius: AdminDeskMetrics.controlRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 17,
                    color: selected ? c.primary : c.textSecondary),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: AdminDeskTypography.caption(c).copyWith(
                    fontSize: 10,
                    color: selected ? c.primary : c.textPrimary,
                    fontWeight: selected
                        ? AdminDeskTypography.bold
                        : AdminDeskTypography.medium,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _search(AdminDeskColors c) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: peerSearchTextController,
        onChanged: (v) => peerSearchText.value = v,
        style: AdminDeskTypography.body(c),
        decoration: InputDecoration(
          hintText: 'جستجوی دستگاه‌ها...',
          hintStyle: AdminDeskTypography.caption(c),
          filled: true,
          fillColor: c.inputBackground,
          isDense: true,
          prefixIcon: Icon(Icons.search_rounded, size: 19,
              color: c.textSecondary),
          suffixIcon: IconButton(
            tooltip: 'پاک‌کردن جستجو',
            icon: Icon(Icons.close_rounded, size: 16,
                color: c.textSecondary),
            onPressed: () {
              peerSearchTextController.clear();
              peerSearchText.value = '';
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: AdminDeskMetrics.controlRadius,
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AdminDeskMetrics.controlRadius,
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AdminDeskMetrics.controlRadius,
            borderSide: BorderSide(color: c.primary),
          ),
        ),
      ),
    );
  }

  Widget _refresh(AdminDeskColors c) {
    return IconButton(
      tooltip: 'تازه‌سازی دستگاه‌ها',
      onPressed: onRefresh,
      icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
    );
  }
}

/// Native data adapter: rows are driven exclusively by filtered peer records
/// from the existing _PeersView loader, not a locally maintained fake list.
class DevicesTable extends StatelessWidget {
  const DevicesTable({
    Key? key,
    required this.peers,
    required this.peerTab,
    required this.onPeerVisible,
    required this.cardKeyPrefix,
  }) : super(key: key);

  final List<Peer> peers;
  final PeerTabIndex peerTab;
  final void Function(String peerId, bool visible) onPeerVisible;
  final String cardKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: AdminDeskMetrics.cardDecoration(c),
        child: Column(
          children: [
            _headers(c),
            Divider(height: 1, color: c.border),
            Expanded(
              child: peers.isEmpty
                  ? Center(child: Text(
                      'دستگاهی با این جستجو یافت نشد',
                      style: AdminDeskTypography.body(c)))
                  : ListView.separated(
                      itemCount: peers.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: c.border),
                      itemBuilder: (context, index) {
                        final peer = peers[index];
                        return VisibilityDetector(
                          key: ValueKey('$cardKeyPrefix${peer.id}'),
                          onVisibilityChanged: (info) =>
                              onPeerVisible(peer.id, info.visibleFraction > 0),
                          child: _DeviceTableRow(peer: peer, peerTab: peerTab),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headers(AdminDeskColors c) {
    final label = AdminDeskTypography.caption(c).copyWith(
        fontWeight: AdminDeskTypography.semibold);
    return SizedBox(
      height: 40,
      child: Row(children: [
        const SizedBox(width: 12),
        Expanded(flex: 4, child: Align(
          alignment: Alignment.centerRight,
          child: Text('نام دستگاه', style: label, textAlign: TextAlign.right),
        )),
        Expanded(flex: 3, child: Align(
          alignment: Alignment.centerRight,
          child: Text('شناسه', style: label, textAlign: TextAlign.right),
        )),
        Expanded(flex: 2, child: Align(
          alignment: Alignment.centerRight,
          child: Text('وضعیت', style: label, textAlign: TextAlign.right),
        )),
        Expanded(flex: 3, child: Align(
          alignment: Alignment.centerRight,
          child: Text('آخرین اتصال', style: label, textAlign: TextAlign.right),
        )),
        const SizedBox(width: 52),
      ]),
    );
  }
}

class _DeviceTableRow extends StatelessWidget {
  const _DeviceTableRow({required this.peer, required this.peerTab});

  final Peer peer;
  final PeerTabIndex peerTab;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    final peerTabs = Provider.of<PeerTabModel>(context);
    final selected = peerTabs.isPeerSelected(peer.id);
    final name = peer.alias.isNotEmpty
        ? peer.alias
        : peer.hostname.isNotEmpty ? peer.hostname : peer.id;
    final online = peer.online;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: selected && peerTabs.multiSelectionMode
              ? c.selectedBackground.withOpacity(0.72)
              : c.surface.withOpacity(0.48),
          child: InkWell(
        hoverColor: c.hoverBackground,
        onDoubleTap: peerTabs.multiSelectionMode
            ? null : () => connectInPeerTab(context, peer, peerTab),
        onTap: peerTabs.multiSelectionMode
            ? () => peerTabs.select(peer) : null,
        onLongPress: () => peerTabs.select(peer),
        child: SizedBox(
          height: 51,
          child: Row(children: [
            const SizedBox(width: 12),
            Expanded(flex: 4, child: Row(children: [
              Icon(_deviceIcon(peer.platform), size: 20, color: c.primary),
              const SizedBox(width: 7),
              Expanded(child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminDeskTypography.body(c).copyWith(
                    fontWeight: AdminDeskTypography.semibold),
              )),
            ])),
            Expanded(flex: 3, child: Align(
              alignment: Alignment.centerRight,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  peer.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: AdminDeskTypography.body(c),
                ),
              ),
            )),
            Expanded(flex: 2, child: Row(children: [
              Icon(Icons.circle, size: 8,
                  color: online ? c.online : c.offline),
              const SizedBox(width: 5),
              Flexible(child: Text(
                online ? 'آنلاین' : 'آفلاین',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminDeskTypography.caption(c).copyWith(
                    color: online ? c.online : c.offline),
              )),
            ])),
            // Peer currently has no authoritative last-connected timestamp.
            // Leave it unspecified rather than inventing a Jalali date/time.
            Expanded(flex: 3, child: Text('—',
                style: AdminDeskTypography.caption(c))),
            SizedBox(
              width: 52,
              child: IconButton(
                tooltip: 'گزینه‌های دستگاه',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
                onPressed: () {
                  final box = context.findRenderObject() as RenderBox?;
                  final position = box == null
                      ? Offset.zero
                      : box.localToGlobal(
                          Offset(box.size.width / 2, box.size.height / 2));
                  showPeerActionsMenu(context, peer, peerTab, position);
                },
              ),
            ),
          ]),
          ),
        ),
      ),
    ));
  }

  IconData _deviceIcon(String platform) {
    final type = platform.toLowerCase();
    if (type.contains('android')) return Icons.android_rounded;
    if (type.contains('windows')) return Icons.desktop_windows_rounded;
    if (type.contains('linux')) return Icons.computer_rounded;
    if (type.contains('mac')) return Icons.laptop_mac_rounded;
    return Icons.monitor_outlined;
  }
}
