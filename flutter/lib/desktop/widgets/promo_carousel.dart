import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_hbb/common.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/admindesk_theme.dart';

/// Four local illustrations: no network requests or external image licensing.
/// Images are shipped by the existing pubspec.yaml "assets/" declaration.
class _PromoSlide {
  const _PromoSlide({
    required this.heading,
    required this.accent,
    required this.description,
    required this.features,
    required this.image,
    this.networkImage,
    this.targetUrl,
    this.adId,
    this.category,
  });

  final String heading;
  final String accent;
  final String description;
  final List<String> features;
  final String image;
  final String? networkImage;
  final String? targetUrl;
  final int? adId;
  final String? category;
}

/// Windows-only promotional carousel. All colors/fonts come from the
/// centralized AdminDesk theme. It owns no Rust/FFI/network application state.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({Key? key}) : super(key: key);

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel>
    with WidgetsBindingObserver {
  static const _slides = <_PromoSlide>[
    _PromoSlide(
      heading: 'مدیریت آسان',
      accent: 'دسترسی ایمن',
      description: 'با AdminDesk همیشه و از هرجا به سیستم‌های خود متصل شوید',
      features: [
        'اتصال سریع و پایدار',
        'امنیت بالا',
        'سازگار با تمام سیستم‌عامل‌ها',
        'پشتیبانی حرفه‌ای',
      ],
      image: 'assets/admindesk_promo_1.svg',
    ),
    _PromoSlide(
      heading: 'ارتباط پایدار',
      accent: 'بدون محدودیت مکان',
      description: 'به دستگاه‌های مجاز خود از راه دور دسترسی داشته باشید',
      features: [
        'مدیریت دستگاه‌های مختلف',
        'اتصال از راه دور',
        'پشتیبانی از چند سیستم‌عامل',
        'دسترسی ساده به دستگاه‌ها',
      ],
      image: 'assets/admindesk_promo_2.svg',
    ),
    _PromoSlide(
      heading: 'کنترل حرفه‌ای',
      accent: 'امنیت بیشتر',
      description: 'از ابزارهای امنیتی و تأیید دسترسی برنامه استفاده کنید',
      features: [
        'رمز عبور یک‌بارمصرف',
        'تأیید اتصال توسط کاربر',
        'امکان انتقال فایل',
        'تنظیمات دسترسی قابل‌کنترل',
      ],
      image: 'assets/admindesk_promo_3.svg',
    ),
    _PromoSlide(
      heading: 'پشتیبانی آسان',
      accent: 'با AdminDesk',
      description: 'برای دسترسی و پشتیبانی سریع‌تر دستگاه‌ها طراحی شده است',
      features: [
        'رابط فارسی و خوانا',
        'فهرست دستگاه‌های ذخیره‌شده',
        'دسترسی به اتصالات اخیر',
        'مدیریت متمرکز ارتباطات',
      ],
      image: 'assets/admindesk_promo_4.svg',
    ),
  ];

  // Advertising is served only by the existing AdminDesk WordPress site.
  // No Admin98 legacy advertising endpoints or credentials are used.
  static const String _wpHost = 'admindesk.ir';
  static const String _categoryOption = 'admindesk_ads_category';
  static const String _categoriesPath = '/wp-json/admindesk/v1/ads/categories';
  static const String _adsPath = '/wp-json/admindesk/v1/ads';
  static const String _eventsPath = '/wp-json/admindesk/v1/ads/events';

  List<_PromoSlide> _activeSlides = _slides;
  List<Map<String, String>> _categories = [];
  String _category = '';
  bool _categoryDialogOpen = false;
  final Set<int> _impressionsThisRun = <int>{};
  late final PageController _controller;
  Timer? _timer;
  Timer? _refreshTimer;
  int _page = 0;
  bool _hovered = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    WidgetsBinding.instance.addObserver(this);
    _loadRemoteAds();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && _foreground) _loadRemoteAds();
    });
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !_hovered && _foreground && _controller.hasClients) {
        _goTo((_page + 1) % _activeSlides.length);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemoteAds({bool reloadCategories = true}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      if (reloadCategories) {
        final categoriesUri = Uri.https(_wpHost, _categoriesPath);
        final categoryRequest = await client
            .getUrl(categoriesUri)
            .timeout(const Duration(seconds: 8));
        final categoryResponse = await categoryRequest
            .close()
            .timeout(const Duration(seconds: 8));
        if (categoryResponse.statusCode == HttpStatus.ok) {
          final raw = await categoryResponse.transform(utf8.decoder).join();
          if (raw.length <= 100000) {
            final decoded = jsonDecode(raw);
            if (decoded is Map && decoded['success'] == true &&
                decoded['categories'] is List) {
              final categories = <Map<String, String>>[];
              for (final item in decoded['categories'] as List) {
                if (item is! Map) continue;
                final slug = item['slug']?.toString() ?? '';
                final name = item['name']?.toString() ?? '';
                if (RegExp(r'^[a-z0-9_-]{1,80}

  Widget _slideArtwork(_PromoSlide slide, double height) {
    final remote = slide.networkImage;
    if (remote != null) {
      return Image.network(remote, height: height, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SvgPicture.asset(slide.image,
              height: height, fit: BoxFit.contain));
    }
    return SvgPicture.asset(slide.image, height: height, fit: BoxFit.contain);
  }

  void _goTo(int target) {
    if (!mounted || !_controller.hasClients) return;
    _controller.animateToPage(
      (target + _activeSlides.length) % _activeSlides.length,
      duration: const Duration(milliseconds: 370),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openPromotion(_PromoSlide slide) async {
    final url = slide.targetUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showDetails(slide);
      return;
    }
    if (slide.adId != null) await _recordEvent(slide, 'click');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showDetails(_PromoSlide slide) {
    final c = AdminDeskColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AdminDeskMetrics.cardRadius,
          ),
          title: Text(
            '${slide.heading} — ${slide.accent}',
            style: AdminDeskTypography.title(c),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slide.description,
                      style: AdminDeskTypography.body(c)),
                  const SizedBox(height: AdminDeskMetrics.spaceMd),
                  ...slide.features.map((feature) =>
                      _feature(context, feature, large: true)),
                  const SizedBox(height: AdminDeskMetrics.spaceSm),
                  _slideArtwork(slide, 165),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('بستن', style:
                  AdminDeskTypography.body(c).copyWith(color: c.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);

    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.promoTop, c.promoBottom],
          ),
          borderRadius: AdminDeskMetrics.cardRadius,
          border: Border.all(color: c.border),
          boxShadow: AdminDeskMetrics.cardShadow(c),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _activeSlides.length,
                onPageChanged: (page) {
                  setState(() => _page = page);
                  if (page >= 0 && page < _activeSlides.length) {
                    _recordImpression(_activeSlides[page]);
                  }
                },
                itemBuilder: (context, index) =>
                    _slide(context, _activeSlides[index], index),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _slide(BuildContext context, _PromoSlide slide, int index) {
    final c = AdminDeskColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AdminDeskMetrics.spaceMd,
            AdminDeskMetrics.spaceSm,
            AdminDeskMetrics.spaceMd,
            AdminDeskMetrics.spaceXs,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.promoBadge,
                    borderRadius: AdminDeskMetrics.controlRadius,
                  ),
                  child: Text(
                    '${index + 1} / ${_activeSlides.length}',
                    textDirection: TextDirection.ltr,
                    style: AdminDeskTypography.caption(c).copyWith(
                      fontWeight: AdminDeskTypography.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'تغییر صنف تبلیغات',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                      padding: EdgeInsets.zero,
                      onPressed: _categories.isEmpty ? null : _showCategoryPicker,
                      icon: Icon(Icons.category_outlined,
                          size: 17, color: c.primary),
                    ),
                    const SizedBox(width: 4),
                    SvgPicture.asset('assets/icon.svg', width: 34, height: 34),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AdminDeskMetrics.spaceMd),
            Text(
              slide.heading,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.heading(c).copyWith(fontSize: 22),
            ),
            Text(
              slide.accent,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.heading(c).copyWith(
                fontSize: 21,
                color: c.primary,
              ),
            ),
            const SizedBox(height: AdminDeskMetrics.spaceSm),
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.body(c).copyWith(height: 1.6),
            ),
            const SizedBox(height: AdminDeskMetrics.spaceMd),
            ...slide.features.map((feature) => _feature(context, feature)),
            const SizedBox(height: AdminDeskMetrics.spaceSm),
            _slideArtwork(slide, constraints.maxHeight < 430 ? 135 : 210),
          ],
        ),
      ),
    );
  }

  Widget _feature(BuildContext context, String text, {bool large = false}) {
    final c = AdminDeskColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminDeskMetrics.spaceXs),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: c.online, size: large ? 18 : 16),
          const SizedBox(width: AdminDeskMetrics.spaceXs),
          Expanded(
            child: Text(
              text,
              style: AdminDeskTypography.body(c).copyWith(
                fontSize: large ? 13 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AdminDeskMetrics.spaceSm,
        AdminDeskMetrics.spaceXs,
        AdminDeskMetrics.spaceSm,
        AdminDeskMetrics.spaceSm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'اسلاید قبلی',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.chevron_left_rounded, color: c.primary),
                  onPressed: () => _goTo(_page - 1),
                ),
                Row(
                  children: List.generate(_activeSlides.length, (index) =>
                    Semantics(
                      label: 'نمایش اسلاید ${index + 1}',
                      button: true,
                      child: InkWell(
                        onTap: () => _goTo(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 210),
                          width: _page == index ? 17 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _page == index
                                ? c.primary : c.offline.withOpacity(.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'اسلاید بعدی',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.chevron_right_rounded, color: c.primary),
                  onPressed: () => _goTo(_page + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminDeskMetrics.spaceXs),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton(
              onPressed: () => _openPromotion(_activeSlides[_page]),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AdminDeskMetrics.controlRadius,
                ),
              ),
              child: Text(
                _activeSlides[_page].targetUrl == null
                    ? 'اطلاعات بیشتر' : 'مشاهده تبلیغ',
                style: AdminDeskTypography.body(c).copyWith(
                  fontWeight: AdminDeskTypography.bold,
                  color: c.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
).hasMatch(slug) &&
                    name.isNotEmpty && name.length <= 100) {
                  categories.add({'slug': slug, 'name': name});
                }
              }
              if (mounted) setState(() => _categories = categories);
            }
          }
        }
      }

      _category = bind.mainGetLocalOption(key: _categoryOption).trim();
      final categoryExists =
          _categories.any((item) => item['slug'] == _category);
      if (_categories.isNotEmpty && (!categoryExists || _category.isEmpty)) {
        await _showCategoryPicker();
      }
      if (_category.isEmpty || !_categories.any((item) => item['slug'] == _category)) {
        return;
      }

      final uri = Uri.https(_wpHost, _adsPath, {'category': _category});
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != HttpStatus.ok) return;
      final raw = await response.transform(utf8.decoder).join();
      if (raw.length > 200000) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['success'] != true ||
          decoded['slides'] is! List) return;

      final slides = <_PromoSlide>[];
      for (final item in (decoded['slides'] as List).take(12)) {
        if (item is! Map) continue;
        final imageUrl = Uri.tryParse(item['image_url']?.toString() ?? '');
        if (imageUrl == null || imageUrl.scheme != 'https' ||
            imageUrl.host != _wpHost) continue;
        final destination = Uri.tryParse(item['target_url']?.toString() ?? '');
        final safeDestination = destination != null &&
                (destination.scheme == 'https' || destination.scheme == 'http') &&
                destination.host.isNotEmpty
            ? destination.toString()
            : null;
        final heading = item['title']?.toString() ?? '';
        final adId = int.tryParse(item['id']?.toString() ?? '');
        if (heading.isEmpty || heading.length > 100 || adId == null || adId <= 0) continue;
        slides.add(_PromoSlide(
          heading: heading,
          accent: (item['subtitle'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          features: item['features'] is List
              ? (item['features'] as List).take(4).map((e) => e.toString()).toList()
              : const <String>[],
          image: 'assets/admindesk_promo_1.svg',
          networkImage: imageUrl.toString(),
          targetUrl: safeDestination,
          adId: adId,
          category: _category,
        ));
      }
      if (!mounted) return;
      setState(() {
        _activeSlides = slides.isEmpty ? _slides : slides;
        _page = 0;
      });
      if (_controller.hasClients) _controller.jumpToPage(0);
      if (slides.isNotEmpty) _recordImpression(slides.first);
    } catch (_) {
      // Offline, invalid feeds or unavailable WordPress retain bundled public slides.
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _showCategoryPicker() async {
    if (!mounted || _categories.isEmpty || _categoryDialogOpen) return;
    _categoryDialogOpen = true;
    String selected = _categories.any((item) => item['slug'] == _category)
        ? _category
        : _categories.first['slug']!;
    try {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('انتخاب صنف فعالیت'),
              content: SizedBox(
                width: 330,
                child: DropdownButtonFormField<String>(
                  value: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'صنف شما',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((item) => DropdownMenuItem<String>(
                    value: item['slug'],
                    child: Text(item['name']!, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selected = value);
                  },
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('ذخیره'),
                ),
              ],
            ),
          ),
        ),
      );
      if (result != null) {
        await bind.mainSetLocalOption(key: _categoryOption, value: result);
        _category = result;
      }
    } finally {
      _categoryDialogOpen = false;
    }
  }

  Future<void> _recordEvent(_PromoSlide slide, String eventType) async {
    final adId = slide.adId;
    if (adId == null) return;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4);
    try {
      final uri = Uri.https(_wpHost, _eventsPath);
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 5));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'ad_id': adId,
        'event_type': eventType,
        'event_id': const Uuid().v4(),
        'category': slide.category ?? '',
      }));
      final response = await request.close().timeout(const Duration(seconds: 5));
      await response.drain<void>();
    } catch (_) {
      // Analytics must never interfere with the remote desktop experience.
    } finally {
      client.close(force: true);
    }
  }

  void _recordImpression(_PromoSlide slide) {
    final id = slide.adId;
    if (id == null || !_impressionsThisRun.add(id)) return;
    _recordEvent(slide, 'impression');
  }

  Widget _slideArtwork(_PromoSlide slide, double height) {
    final remote = slide.networkImage;
    if (remote != null) {
      return Image.network(remote, height: height, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SvgPicture.asset(slide.image,
              height: height, fit: BoxFit.contain));
    }
    return SvgPicture.asset(slide.image, height: height, fit: BoxFit.contain);
  }

  void _goTo(int target) {
    if (!mounted || !_controller.hasClients) return;
    _controller.animateToPage(
      (target + _activeSlides.length) % _activeSlides.length,
      duration: const Duration(milliseconds: 370),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _openPromotion(_PromoSlide slide) async {
    final url = slide.targetUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showDetails(slide);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showDetails(_PromoSlide slide) {
    final c = AdminDeskColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AdminDeskMetrics.cardRadius,
          ),
          title: Text(
            '${slide.heading} — ${slide.accent}',
            style: AdminDeskTypography.title(c),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(slide.description,
                      style: AdminDeskTypography.body(c)),
                  const SizedBox(height: AdminDeskMetrics.spaceMd),
                  ...slide.features.map((feature) =>
                      _feature(context, feature, large: true)),
                  const SizedBox(height: AdminDeskMetrics.spaceSm),
                  _slideArtwork(slide, 165),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('بستن', style:
                  AdminDeskTypography.body(c).copyWith(color: c.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminDeskColors.of(context);

    return MouseRegion(
      onEnter: (_) => _hovered = true,
      onExit: (_) => _hovered = false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.promoTop, c.promoBottom],
          ),
          borderRadius: AdminDeskMetrics.cardRadius,
          border: Border.all(color: c.border),
          boxShadow: AdminDeskMetrics.cardShadow(c),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _activeSlides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) =>
                    _slide(context, _activeSlides[index], index),
              ),
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _slide(BuildContext context, _PromoSlide slide, int index) {
    final c = AdminDeskColors.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AdminDeskMetrics.spaceMd,
            AdminDeskMetrics.spaceSm,
            AdminDeskMetrics.spaceMd,
            AdminDeskMetrics.spaceXs,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.promoBadge,
                    borderRadius: AdminDeskMetrics.controlRadius,
                  ),
                  child: Text(
                    '${index + 1} / ${_activeSlides.length}',
                    textDirection: TextDirection.ltr,
                    style: AdminDeskTypography.caption(c).copyWith(
                      fontWeight: AdminDeskTypography.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                SvgPicture.asset('assets/icon.svg', width: 34, height: 34),
              ],
            ),
            const SizedBox(height: AdminDeskMetrics.spaceMd),
            Text(
              slide.heading,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.heading(c).copyWith(fontSize: 22),
            ),
            Text(
              slide.accent,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.heading(c).copyWith(
                fontSize: 21,
                color: c.primary,
              ),
            ),
            const SizedBox(height: AdminDeskMetrics.spaceSm),
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: AdminDeskTypography.body(c).copyWith(height: 1.6),
            ),
            const SizedBox(height: AdminDeskMetrics.spaceMd),
            ...slide.features.map((feature) => _feature(context, feature)),
            const SizedBox(height: AdminDeskMetrics.spaceSm),
            _slideArtwork(slide, constraints.maxHeight < 430 ? 135 : 210),
          ],
        ),
      ),
    );
  }

  Widget _feature(BuildContext context, String text, {bool large = false}) {
    final c = AdminDeskColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminDeskMetrics.spaceXs),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: c.online, size: large ? 18 : 16),
          const SizedBox(width: AdminDeskMetrics.spaceXs),
          Expanded(
            child: Text(
              text,
              style: AdminDeskTypography.body(c).copyWith(
                fontSize: large ? 13 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final c = AdminDeskColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AdminDeskMetrics.spaceSm,
        AdminDeskMetrics.spaceXs,
        AdminDeskMetrics.spaceSm,
        AdminDeskMetrics.spaceSm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'اسلاید قبلی',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.chevron_left_rounded, color: c.primary),
                  onPressed: () => _goTo(_page - 1),
                ),
                Row(
                  children: List.generate(_activeSlides.length, (index) =>
                    Semantics(
                      label: 'نمایش اسلاید ${index + 1}',
                      button: true,
                      child: InkWell(
                        onTap: () => _goTo(index),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 210),
                          width: _page == index ? 17 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _page == index
                                ? c.primary : c.offline.withOpacity(.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'اسلاید بعدی',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.chevron_right_rounded, color: c.primary),
                  onPressed: () => _goTo(_page + 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: AdminDeskMetrics.spaceXs),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton(
              onPressed: () => _openPromotion(_activeSlides[_page]),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AdminDeskMetrics.controlRadius,
                ),
              ),
              child: Text(
                _activeSlides[_page].targetUrl == null
                    ? 'اطلاعات بیشتر' : 'مشاهده تبلیغ',
                style: AdminDeskTypography.body(c).copyWith(
                  fontWeight: AdminDeskTypography.bold,
                  color: c.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
