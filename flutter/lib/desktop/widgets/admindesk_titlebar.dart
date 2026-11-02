import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

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
      padding: const EdgeInsets.only(left: 19),
      child: Row(
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
        content: SingleChildScrollView(child: Text(message)),
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
    final colors = AdminDeskColors.of(context);
    final unread = _unreadCount;
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
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: colors.textPrimary,
          ),
          if (unread > 0)
            Positioned(
              top: -5,
              right: -8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFE34D4D),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (widget.hasUpdate)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors.notification,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
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
  static final Uri _notificationsEndpoint = Uri(
    scheme: 'https',
    host: 'admindesk.ir',
    path: '/wp-json/admindesk/v1/notifications',
    queryParameters: {'audience': 'all'},
  );

  Timer? _timer;
  bool _checking = false;
  final Map<String, int?> _latencies = {
    'Rendezvous (TCP 21116)': null,
    'Relay (TCP 21117)': null,
    'Notifications (HTTPS)': null,
    'Update hosting (HTTPS)': null,
  };

  bool get _allAvailable =>
      _latencies.values.every((latency) => latency != null);
  bool get _anyAvailable =>
      _latencies.values.any((latency) => latency != null);

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

  Future<int?> _checkTcp(int port) async {
    final watch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        _host,
        port,
        timeout: const Duration(seconds: 3),
      );
      watch.stop();
      return watch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<int?> _checkNotifications() async {
    final watch = Stopwatch()..start();
    try {
      final response = await http.get(
        _notificationsEndpoint,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      watch.stop();
      return response.statusCode == HttpStatus.ok
          ? watch.elapsedMilliseconds
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<int?> _checkUpdateHosting() async {
    final watch = Stopwatch()..start();
    try {
      final response = await http.head(
        Uri.parse('https://update.admindesk.ir/'),
      ).timeout(const Duration(seconds: 5));
      watch.stop();
      // A 4xx response still proves that the HTTPS host is reachable.
      return response.statusCode < HttpStatus.internalServerError
          ? watch.elapsedMilliseconds
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    if (mounted) setState(() {});
    final results = await Future.wait<int?>([
      _checkTcp(21116),
      _checkTcp(21117),
      _checkNotifications(),
      _checkUpdateHosting(),
    ]);
    if (mounted) {
      setState(() {
        _latencies['Rendezvous (TCP 21116)'] = results[0];
        _latencies['Relay (TCP 21117)'] = results[1];
        _latencies['Notifications (HTTPS)'] = results[2];
        _latencies['Update hosting (HTTPS)'] = results[3];
        _checking = false;
      });
    } else {
      _checking = false;
    }
  }

  String _serviceLabel(String name, int? latency) {
    if (latency == null) return '$name: در دسترس نیست';
    return '$name: متصل · $latency ms';
  }

  @override
  Widget build(BuildContext context) {
    final Color signalColor = _checking
        ? AdminDeskColors.light.textSecondary
        : _allAvailable
            ? const Color(0xFF16A765)
            : _anyAvailable
                ? const Color(0xFFE6A323)
                : const Color(0xFFE34D4D);
    final tooltip = [
      'وضعیت سرویس‌های AdminDesk',
      for (final entry in _latencies.entries)
        _serviceLabel(entry.key, entry.value),
      'این بررسی دسترسی TCP/HTTPS را می‌سنجد و سلامت کامل نشست یا UDP را تضمین نمی‌کند.',
    ].join('\n');

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: IconButton(
        tooltip: 'بررسی سرویس‌های سرور',
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        padding: EdgeInsets.zero,
        onPressed: _checking ? null : _check,
        icon: _checking
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: signalColor,
                ),
              )
            : Icon(
                Icons.wifi_tethering_rounded,
                size: 21,
                color: signalColor,
              ),
      ),
    );
  }
}
