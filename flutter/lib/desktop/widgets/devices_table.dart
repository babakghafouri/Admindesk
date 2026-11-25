import 'package:flutter/material.dart';
import '../../common/formatter/id_formatter.dart';
import '../../models/platform_model.dart';
import 'package:get/get.dart';
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
    required this.onViewModeChanged,
    required Widget child,
  }) : super(key: key, child: child);

  final bool enabled;
  final ValueChanged<PeerUiType> onViewModeChanged;

  static DevicesTableScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DevicesTableScope>();

  static bool enabledOf(BuildContext context) => maybeOf(context)?.enabled ?? false;

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
    this.onViewModeChanged,
    this.statusFilter,
    this.onStatusFilterChanged,
    this.showNavigation = true,
  }) : super(key: key);

  final int currentTab;
  final List<int> availableTabs;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onRefresh;
  final ValueChanged<PeerUiType>? onViewModeChanged;
  final String? statusFilter;
  final ValueChanged<String>? onStatusFilterChanged;
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
              ? (constraints.maxWidth < 560
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: search),
                          if (statusFilter != null && onStatusFilterChanged != null)
                            _statusFilter(c),
                          _refresh(c),
                        ]),
                        const SizedBox(height: AdminDeskMetrics.spaceXs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _viewModeControl(context, c),
                        ),
                      ],
                    )
                  : Row(children: [
                      Expanded(child: search),
                      if (statusFilter != null && onStatusFilterChanged != null)
                        _statusFilter(c),
                      const SizedBox(width: AdminDeskMetrics.spaceXs),
                      _viewModeControl(context, c),
                      _refresh(c),
                    ]))
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
                      if (statusFilter != null && onStatusFilterChanged != null)
                        _statusFilter(c),
                      _refresh(c),
                    ]),
                  ],
                )
              : Row(children: [
                  ...tabs,
                  const SizedBox(width: AdminDeskMetrics.spaceSm),
                  Expanded(child: search),
                  if (statusFilter != null && onStatusFilterChanged != null)
                    _statusFilter(c),
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

  Widget _viewModeControl(BuildContext context, AdminDeskColors c) {
    return Obx(() => Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.inputBackground,
            border: Border.all(color: c.border),
            borderRadius: AdminDeskMetrics.controlRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewModeButton(
                context,
                c,
                mode: PeerUiType.grid,
                icon: Icons.grid_view_rounded,
                label: 'کارتی',
                onChanged: onViewModeChanged,
              ),
              _viewModeButton(
                context,
                c,
                mode: PeerUiType.list,
                icon: Icons.view_list_rounded,
                label: 'لیستی',
                onChanged: onViewModeChanged,
              ),
            ],
          ),
        ));
  }

  Widget _viewModeButton(
    BuildContext context,
    AdminDeskColors c, {
    required PeerUiType mode,
    required IconData icon,
    required String label,
    ValueChanged<PeerUiType>? onChanged,
  }) {
    final selected = peerCardUiType.value == mode;
    return Tooltip(
      message: 'نمایش $label',
      child: Material(
        color: selected ? c.selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            if (peerCardUiType.value == mode) return;
            onChanged?.call(mode);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AdminDeskTypography.caption(c).copyWith(
                    color: selected ? c.primary : c.textPrimary,
                    fontWeight: selected
                        ? AdminDeskTypography.bold
                        : AdminDeskTypography.medium,
                  ),
                ),
              ],
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

  Widget _statusFilter(AdminDeskColors c) {
    return Wrap(spacing: 5, children: [
      for (final entry in const {'all': 'همه', 'online': 'آنلاین', 'offline': 'آفلاین'}.entries)
        ChoiceChip(
          label: Text(entry.value, style: AdminDeskTypography.body(c)),
          selected: statusFilter == entry.key,
          onSelected: (_) => onStatusFilterChanged?.call(entry.key),
          selectedColor: c.selectedBackground,
          visualDensity: VisualDensity.compact,
          showCheckmark: false,
        ),
    ]);
  }

  Widget _refresh(AdminDeskColors c) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: 'تازه‌سازی دستگاه‌ها',
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onRefresh,
        icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
      ),
    );
  }
}

/// Native data adapter: rows are driven exclusively by filtered peer records
/// from the existing _PeersView loader, not a locally maintained fake list.
class DevicesTable extends StatefulWidget {
  const DevicesTable({super.key, required this.peers, required this.peerTab,
    required this.onPeerVisible, required this.cardKeyPrefix});
  final List<Peer> peers;
  final PeerTabIndex peerTab;
  final void Function(String peerId, bool visible) onPeerVisible;
  final String cardKeyPrefix;
  @override
  State<DevicesTable> createState() => _DevicesTableState();
}

class _DevicesTableState extends State<DevicesTable> {
  bool _onlineOpen = true;
  bool _offlineOpen = false;

  @override
  void initState() {
    super.initState();
    _onlineOpen = bind.getLocalFlutterOption(k: 'admindesk-online-expanded') != 'N';
    _offlineOpen = bind.getLocalFlutterOption(k: 'admindesk-offline-expanded') == 'Y';
  }

  Widget _header(AdminDeskColors c, bool online, int count) {
    final open = online ? _onlineOpen : _offlineOpen;
    return Material(
      color: c.canvas,
      child: InkWell(
        onTap: () {
          setState(() {
            if (online) {
              _onlineOpen = !open;
            } else {
              _offlineOpen = !open;
            }
          });
          bind.setLocalFlutterOption(
            k: online ? 'admindesk-online-expanded' : 'admindesk-offline-expanded',
            v: !open ? 'Y' : 'N');
        },
        child: SizedBox(height: 40, child: Row(children: [
          const SizedBox(width: 12),
          Icon(open ? Icons.expand_more : Icons.chevron_left, color: c.textSecondary),
          const SizedBox(width: 8),
          Text(online ? 'آنلاین ($count)' : 'آفلاین ($count)',
            style: AdminDeskTypography.title(c).copyWith(
              fontSize: 13, color: online ? c.online : c.textSecondary)),
        ])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    final online = widget.peers.where((p) => p.online).toList();
    final offline = widget.peers.where((p) => !p.online).toList();
    final showOffline = _offlineOpen || peerStatusFilter.value == 'offline';
    final showOnline = _onlineOpen || peerStatusFilter.value == 'online';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        borderRadius: AdminDeskMetrics.cardRadius,
        child: DecoratedBox(
          decoration: AdminDeskMetrics.cardDecoration(c),
          child: ListView(
            children: [
              if (online.isNotEmpty) _header(c, true, online.length),
              if (showOnline) for (final peer in online) _row(peer, c),
              if (offline.isNotEmpty) _header(c, false, offline.length),
              if (showOffline) for (final peer in offline) _row(peer, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(Peer peer, AdminDeskColors c) => VisibilityDetector(
    key: ValueKey('${widget.cardKeyPrefix}${peer.id}'),
    onVisibilityChanged: (info) => widget.onPeerVisible(peer.id, info.visibleFraction > 0),
    child: Column(children: [
      _DeviceTableRow(peer: peer, peerTab: widget.peerTab),
      Divider(height: 1, thickness: 1, color: c.border),
    ]),
  );
}

class _DeviceTableRow extends StatelessWidget {
  const _DeviceTableRow({required this.peer, required this.peerTab});
  final Peer peer;
  final PeerTabIndex peerTab;

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);
    final model = Provider.of<PeerTabModel>(context);
    final host = '${peer.username}${peer.username.isNotEmpty && peer.hostname.isNotEmpty ? '@' : ''}${peer.hostname}';
    final name = peer.alias.isNotEmpty ? peer.alias : host.isNotEmpty ? host : peer.id;
    final online = peer.online;
    void connectPeer() => connectInPeerTab(context, peer, peerTab);
    return Tooltip(
      message: online ? 'دوبار کلیک = اتصال' : 'دستگاه آفلاین است',
      child: Material(
        color: model.multiSelectionMode && model.isPeerSelected(peer.id)
            ? c.selectedBackground : c.surface,
        child: InkWell(
          hoverColor: c.hoverBackground,
          onDoubleTap: online && !model.multiSelectionMode ? connectPeer : null,
          onTap: model.multiSelectionMode ? () => model.select(peer) : null,
          onLongPress: () => model.select(peer),
          child: SizedBox(height: 49, child: Row(children: [
            const SizedBox(width: 12),
            if (model.multiSelectionMode)
              Icon(model.isPeerSelected(peer.id) ? Icons.check_box : Icons.check_box_outline_blank)
            else PeerFavoriteButton(peer: peer, tab: peerTab),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 10, color: online ? c.online : c.offline),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: Tooltip(message: name, child: Text(name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AdminDeskTypography.body(c).copyWith(
                color: online ? c.textPrimary : c.textSecondary,
                fontWeight: FontWeight.w600)))),
            Expanded(flex: 3, child: Text(formatID(peer.id),
              textDirection: TextDirection.ltr, textAlign: TextAlign.right,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                color: online ? c.primary : c.textSecondary))),
            SizedBox(width: 90, child: PeerConnectButton(online: online, onConnect: connectPeer)),
            IconButton(tooltip: 'ویرایش', iconSize: 17,
              onPressed: () => renameDashboardPeer(context, peer, peerTab),
              icon: Icon(Icons.edit_outlined, color: c.textSecondary)),
            Builder(builder: (buttonContext) => IconButton(
              tooltip: 'گزینه‌های دستگاه', iconSize: 19,
              icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
              onPressed: () {
                final box = buttonContext.findRenderObject() as RenderBox?;
                showPeerActionsMenu(context, peer, peerTab,
                  box?.localToGlobal(Offset.zero) ?? Offset.zero);
              },
            )),
            const SizedBox(width: 8),
          ])),
        ),
      ),
    );
  }
}
