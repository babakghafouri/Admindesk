import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart' show createDialogContent, MyTheme;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        'اتصال امن، مدیریت آسان',
        style: AdminDeskTypography.title(colors).copyWith(fontSize: 15),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminDeskServerHealth(),
        const SizedBox(width: AdminDeskMetrics.spaceXs),
        Obx(() {
          final hasUpdate = stateGlobal.updateUrl.value.isNotEmpty;
          return AdminDeskNotifications(
            hasUpdate: hasUpdate,
            settingsEnabled: settingsEnabled,
            onUpdateTap: onSettings,
          );
        }),
        const SizedBox(width: AdminDeskMetrics.spaceXs),
        PopupMenuButton<ThemeMode>(
          tooltip: 'تغییر تم',
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 19,
          ),
          onSelected: (mode) => MyTheme.changeDarkMode(mode),
          itemBuilder: (_) => const [
            PopupMenuItem(value: ThemeMode.system, child: Text('تم سیستم')),
            PopupMenuItem(value: ThemeMode.light, child: Text('روشن')),
            PopupMenuItem(value: ThemeMode.dark, child: Text('تیره')),
          ],
        ),
      ],
    );
  }
}


/// Reads public AdminDesk announcements from the WordPress REST API.
/// Read IDs are stored in the app support directory on this device.
class AdminDeskNotifications extends StatefulWidget {
  const AdminDeskNotifications({
    Key? key,
    required this.hasUpdate,
    required this.settingsEnabled,
    required this.onUpdateTap,
  }) : super(key: key);

  final bool hasUpdate;
  final bool settingsEnabled;
  final VoidCallback onUpdateTap;

  @override
  State<AdminDeskNotifications> createState() => _AdminDeskNotificationsState();
}

class _AdminDeskNotificationsState extends State<AdminDeskNotifications> {
  static final Uri _endpoint = Uri.parse(
    'https://admindesk.ir/wp-json/admindesk/v1/notifications?audience=all',
  );
  static const Duration _refreshInterval = Duration(minutes: 5);

  Timer? _timer;
  bool _fetching = false;
  List<Map<String, dynamic>> _notifications = [];
  final Set<String> _readIds = <String>{};

  int get _unreadCount => _notifications.where((item) {
        final id = (item['id'] ?? '').toString();
        return id.isNotEmpty && !_readIds.contains(id);
      }).length;

  @override
  void initState() {
    super.initState();
    _loadReadIds();
    _fetchNotifications();
    _timer = Timer.periodic(_refreshInterval, (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> _readStateFile() async {
    final directory = await getApplicationSupportDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}admindesk_notifications.json');
  }

  Future<void> _loadReadIds() async {
    try {
      final file = await _readStateFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is List) {
        _readIds.addAll(decoded.map((value) => value.toString()));
        if (mounted) setState(() {});
      }
    } catch (_) {
      // A missing or damaged local read-state file must not block notices.
    }
  }

  Future<void> _saveReadIds() async {
    try {
      final file = await _readStateFile();
      await file.writeAsString(jsonEncode(_readIds.toList()));
    } catch (_) {
      // The current session still keeps the read state in memory.
    }
  }

  Future<void> _fetchNotifications() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final response = await http.get(
        _endpoint,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw HttpException('Notification API returned ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['success'] != true) {
        throw const FormatException('Invalid notification response');
      }
      final rawItems = decoded['notifications'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _notifications = items;
        });
      }
    } catch (_) {
      // Keep the last successful response; the titlebar remains usable offline.
    } finally {
      _fetching = false;
    }
  }

  void _openNotification(int index) {
    if (index < 0 || index >= _notifications.length) return;
    final item = _notifications[index];
    final id = (item['id'] ?? '').toString();
    if (id.isNotEmpty && _readIds.add(id)) {
      setState(() {});
      _saveReadIds();
    }

    final title = (item['title'] ?? 'اطلاعیه AdminDesk').toString();
    final message = (item['message'] ?? '').toString();
    final priority = (item['priority'] ?? 'normal').toString();
    final isImportant = priority == 'important' || priority == 'critical';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isImportant ? Icons.warning_amber_rounded : Icons.notifications_none_rounded,
              color: isImportant ? Colors.orange : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(child: createDialogContent(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount;
    final displayCount = unread > 0 ? unread : (widget.hasUpdate ? 1 : 0);
    return PopupMenuButton<int>(
      tooltip: unread > 0 ? '$unread اعلان خوانده‌نشده' : 'اعلان‌ها',
      padding: EdgeInsets.zero,
      onOpened: _fetchNotifications,
      onSelected: (value) {
        if (value == -2) {
          if (widget.settingsEnabled) widget.onUpdateTap();
        } else {
          _openNotification(value);
        }
      },
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: widget.hasUpdate ? const Color(0xFFFFEEE9) : const Color(0xFFE7F6EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.hasUpdate ? 'نسخه جدید موجود است' : 'نسخه شما به‌روز است',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: widget.hasUpdate ? const Color(0xFFC83F24) : const Color(0xFF14875D))),
            const SizedBox(width: 5),
            if (displayCount > 0) Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: widget.hasUpdate ? const Color(0xFFC83F24) : const Color(0xFF14875D), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(displayCount > 9 ? '9+' : displayCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ]),
      itemBuilder: (_) {
        final items = <PopupMenuEntry<int>>[
          const PopupMenuItem<int>(
            enabled: false,
            child: Text('اطلاعیه‌های AdminDesk'),
          ),
        ];
        if (_notifications.isEmpty) {
          items.add(const PopupMenuItem<int>(
            enabled: false,
            child: Text('اطلاعیه تازه‌ای وجود ندارد'),
          ));
        } else {
          for (var index = 0; index < _notifications.length; index++) {
            final item = _notifications[index];
            final id = (item['id'] ?? '').toString();
            final isUnread = id.isNotEmpty && !_readIds.contains(id);
            final title = (item['title'] ?? 'اطلاعیه').toString();
            final priority = (item['priority'] ?? 'normal').toString();
            items.add(PopupMenuItem<int>(
              value: index,
              child: SizedBox(
                width: 250,
                child: Row(
                  children: [
                    Icon(
                      priority == 'critical' || priority == 'important'
                          ? Icons.priority_high_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: priority == 'critical'
                          ? Colors.red
                          : priority == 'important'
                              ? Colors.orange
                              : colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AdminDeskTypography.body(colors).copyWith(
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2878E8),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ));
          }
        }
        if (widget.hasUpdate) {
          items.add(const PopupMenuDivider());
          items.add(PopupMenuItem<int>(
            value: -2,
            enabled: widget.settingsEnabled,
            child: const Text('به‌روزرسانی جدید در دسترس است'),
          ));
        }
        return items;
      },
    );
  }
}


/// Independent reachability checks for the rendezvous, relay, and
/// WordPress notification services. These checks do not claim to test a
/// complete remote session; they only report each service endpoint.
class AdminDeskServerHealth extends StatefulWidget {
  const AdminDeskServerHealth({Key? key}) : super(key: key);

  @override
  State<AdminDeskServerHealth> createState() => _AdminDeskServerHealthState();
}

class _AdminDeskServerHealthState extends State<AdminDeskServerHealth> {
  static const String _host = 'desk.admin98.ir';
  Timer? _timer;
  bool _checking = false;
  bool? _connected;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _checkTcp(int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        _host,
        port,
        timeout: const Duration(seconds: 3),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    final results = await Future.wait<bool>([
      _checkTcp(21116),
      _checkTcp(21117),
    ]);
    if (mounted) {
      setState(() {
        _connected = results.every((available) => available);
        _checking = false;
      });
    }
  }

  String get _status => _connected == null
      ? 'در حال بررسی'
      : _connected!
          ? 'متصل و آماده به کار'
          : 'قطع';

  Color get _statusColor => _connected == null
      ? AdminDeskColors.light.textSecondary
      : _connected!
          ? const Color(0xFF16A765)
          : const Color(0xFFE34D4D);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'وضعیت: $_status',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _checking ? null : _check,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_tethering_rounded,
                  size: 19, color: _statusColor),
              const SizedBox(width: 5),
              Text(_status,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 11, color: _statusColor)),
            ],
          ),
        ),
      ),
    );
  }
}
