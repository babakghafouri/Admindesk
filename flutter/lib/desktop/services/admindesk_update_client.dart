import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// WordPress update metadata is advisory, never an authority to execute code.
/// This downloader stages a verified installer; it never launches the EXE.
class AdminDeskRelease {
  const AdminDeskRelease({
    required this.version,
    required this.arch,
    required this.url,
    required this.sha256Hex,
    required this.changelog,
  });

  final String version;
  final String arch;
  final Uri url;
  final String sha256Hex;
  final String changelog;
}

class AdminDeskUpdateClient {
  static final Uri _api = Uri.parse(
    'https://admindesk.ir/wp-json/admindesk/v1/update',
  );
  static const int _maxInstallerBytes = 500 * 1024 * 1024;
  static final RegExp _versionFormat = RegExp(r'^\d+\.\d+\.\d+$');
  static final RegExp _hashFormat = RegExp(r'^[a-fA-F0-9]{64}$');

  /// Resolve the architecture of the running Flutter process so x86 clients
  /// never receive the x64 installer (and vice versa).
  static String get windowsFlutterArch {
    final abi = Abi.current();
    if (abi == Abi.windowsX64) return 'x64';
    if (abi == Abi.windowsIA32) return 'x86';
    throw UnsupportedError('Unsupported AdminDesk Windows architecture: $abi');
  }

  static int _compareVersions(String left, String right) {
    final a = left.split('.').map(int.parse).toList();
    final b = right.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      final c = a[i].compareTo(b[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  static Future<AdminDeskRelease?> check() async {
    if (!Platform.isWindows) return null;
    final current = (await PackageInfo.fromPlatform()).version;
    if (!_versionFormat.hasMatch(current)) return null;
    final uri = _api.replace(queryParameters: {
      'platform': 'windows',
      'arch': windowsFlutterArch,
      'current_version': current,
    });
    final client = http.Client();
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      request.headers['Accept'] = 'application/json';
      final response = await client.send(request).timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      final bytes = await response.stream.toBytes();
      if (bytes.length > 65536) return null;
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is! Map || raw['success'] != true ||
          raw['update_available'] != true) {
        return null;
      }
      final version = raw['version'];
      final sha = raw['sha256'];
      final url = raw['url'];
      if (version is! String || !_versionFormat.hasMatch(version) ||
          _compareVersions(version, current) <= 0 ||
          sha is! String || !_hashFormat.hasMatch(sha) ||
          url is! String) {
        return null;
      }
      final downloadUri = Uri.tryParse(url);
      if (downloadUri == null ||
          downloadUri.scheme != 'https' ||
          downloadUri.host != 'update.admindesk.ir' ||
          downloadUri.userInfo.isNotEmpty ||
          downloadUri.hasFragment ||
          downloadUri.port != 443) {
        return null;
      }
      return AdminDeskRelease(
        version: version,
        arch: windowsFlutterArch,
        url: downloadUri,
        sha256Hex: sha.toLowerCase(),
        changelog: raw['changelog'] is String ? raw['changelog'] as String : '',
      );
    } finally {
      client.close();
    }
  }

  /// Stream into a temporary file with a size limit. Reject redirects and
  /// compare SHA-256 after the transfer; never run the downloaded installer.
  static Future<File> downloadVerified(AdminDeskRelease release) async {
    final directory = Directory(
      '${(await getApplicationSupportDirectory()).path}'
      '${Platform.pathSeparator}admindesk-updates',
    );
    await directory.create(recursive: true);
    final name = 'AdminDesk-${release.version}-${release.arch}.exe';
    final destination = File('${directory.path}${Platform.pathSeparator}$name');
    final temporary = File('${destination.path}.part');
    final client = http.Client();
    try {
      if (await temporary.exists()) await temporary.delete();
      final request = http.Request('GET', release.url)
        ..followRedirects = false;
      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw const HttpException('Installer download did not return HTTP 200');
      }
      if (response.contentLength != null &&
          response.contentLength! > _maxInstallerBytes) {
        throw const FormatException('Installer exceeds allowed size');
      }
      final sink = temporary.openWrite();
      var size = 0;
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          size += chunk.length;
          if (size > _maxInstallerBytes) {
            throw const FormatException('Installer exceeds allowed size');
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (size == 0) {
        throw const FormatException('Empty installer');
      }
      final actualHash = (await sha256.bind(temporary.openRead()).first)
          .toString().toLowerCase();
      if (actualHash != release.sha256Hex) {
        throw const FormatException('Installer SHA-256 verification failed');
      }
      if (await destination.exists()) await destination.delete();
      return await temporary.rename(destination.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    } finally {
      client.close();
    }
  }
}
