import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'admindesk_update_client.dart';

/// Non-invasive update entry point next to existing WordPress notifications.
/// A successful check never installs software without explicit user action.
class AdminDeskUpdateAction extends StatefulWidget {
  const AdminDeskUpdateAction({Key? key}) : super(key: key);

  @override
  State<AdminDeskUpdateAction> createState() => _AdminDeskUpdateActionState();
}

class _AdminDeskUpdateActionState extends State<AdminDeskUpdateAction> {
  Timer? _timer;
  bool _checking = false;
  bool _downloading = false;
  AdminDeskRelease? _release;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || _downloading) return;
    _checking = true;
    try {
      final release = await AdminDeskUpdateClient.check();
      if (mounted) setState(() => _release = release);
    } catch (_) {
      // A transient API problem never blocks remote access or notifications.
    } finally {
      _checking = false;
    }
  }

  Future<void> _showUpdates() async {
    await _check();
    if (!mounted) return;
    final release = _release;
    if (release == null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('به‌روزرسانی AdminDesk'),
          content: const Text('نسخه جدیدی شناسایی نشد یا سرور در دسترس نیست.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('بستن'),
            ),
          ],
        ),
      );
      return;
    }

    var status = '';
    var busy = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          title: Text('نسخه جدید AdminDesk ${release.version}'),
          content: SizedBox(
            width: 390,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('دانلود فقط با درخواست شما انجام می‌شود. '
                    'فایل پس از دریافت با SHA-256 بررسی خواهد شد؛ '
                    'نصب خودکار فعال نیست.'),
                if (release.changelog.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(release.changelog),
                ],
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SelectableText(status),
                ],
                if (busy) const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(ctx).pop(),
              child: const Text('بستن'),
            ),
            ElevatedButton(
              onPressed: busy ? null : () async {
                busy = true;
                updateDialog(() => status = 'در حال دریافت و بررسی فایل...');
                if (mounted) setState(() => _downloading = true);
                try {
                  final file = await AdminDeskUpdateClient.downloadVerified(release);
                  if (!ctx.mounted) return;
                  updateDialog(() => status =
                      'SHA-256 تأیید شد. فایل در مسیر زیر ذخیره شده است. '
                      'نصب را فقط بعد از بررسی امضای ناشر و با تأیید خودتان انجام دهید:\n${file.path}');
                  // Open Explorer to the verified file; never execute it.
                  if (Platform.isWindows) {
                    await Process.run('explorer.exe', ['/select,', file.path]);
                  }
                } catch (error) {
                  if (ctx.mounted) {
                    updateDialog(() => status =
                        'دریافت یا اعتبارسنجی ناموفق بود. هیچ فایلی اجرا نشد.\n$error');
                  }
                } finally {
                  busy = false;
                  if (ctx.mounted) updateDialog(() {});
                  if (mounted) setState(() => _downloading = false);
                }
              },
              child: const Text('دانلود و بررسی صحت فایل'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _release == null
          ? 'بررسی به‌روزرسانی AdminDesk'
          : 'نسخه ${_release!.version} آماده دریافت است',
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
      onPressed: _downloading ? null : _showUpdates,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.system_update_alt_rounded, size: 20),
          if (_release != null)
            Positioned(
              top: -2,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF168D62),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
