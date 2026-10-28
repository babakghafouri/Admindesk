import 'package:flutter/material.dart';

/// Design tokens for the Windows AdminDesk UI.
///
/// This extension is deliberately presentation-only. It does not modify the
/// connection state, FFI, network, security settings, or Android-specific UI.
/// Future desktop widgets must read these colors rather than defining local
/// hexadecimal colors.
@immutable
class AdminDeskColors extends ThemeExtension<AdminDeskColors> {
  final Color primary;
  final Color primaryHover;
  final Color canvas;
  final Color surface;
  final Color sidebar;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputBackground;
  final Color selectedBackground;
  final Color hoverBackground;
  final Color online;
  final Color inUse;
  final Color offline;
  final Color notification;
  final Color shadow;
  final Color onPrimary;
  final Color promoTop;
  final Color promoBottom;
  final Color promoBadge;

  const AdminDeskColors({
    required this.primary,
    required this.primaryHover,
    required this.canvas,
    required this.surface,
    required this.sidebar,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputBackground,
    required this.selectedBackground,
    required this.hoverBackground,
    required this.online,
    required this.inUse,
    required this.offline,
    required this.notification,
    required this.shadow,
    required this.onPrimary,
    required this.promoTop,
    required this.promoBottom,
    required this.promoBadge,
  });

  static const light = AdminDeskColors(
    primary: Color(0xFF1F6FEB),
    primaryHover: Color(0xFF2F6BFF),
    canvas: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    sidebar: Color(0xFFFFFFFF),
    border: Color(0xFFE6EAF1),
    textPrimary: Color(0xFF1B2430),
    textSecondary: Color(0xFF6B7686),
    inputBackground: Color(0xFFF9FAFC),
    selectedBackground: Color(0xFFE8F1FF),
    hoverBackground: Color(0xFFF1F6FF),
    online: Color(0xFF22C55E),
    inUse: Color(0xFFF59E0B),
    offline: Color(0xFF9AA4B2),
    notification: Color(0xFFEF4444),
    shadow: Color(0x140E2F58),
    onPrimary: Color(0xFFFFFFFF),
    promoTop: Color(0xFFEAF6FF),
    promoBottom: Color(0xFFBBDEFF),
    promoBadge: Color(0xFFD5E8FF),
  );

  static const dark = AdminDeskColors(
    primary: Color(0xFF5097FF),
    primaryHover: Color(0xFF7AAFFF),
    canvas: Color(0xFF171B25),
    surface: Color(0xFF222938),
    sidebar: Color(0xFF1C2331),
    border: Color(0xFF364254),
    textPrimary: Color(0xFFF2F6FC),
    textSecondary: Color(0xFFABB9CA),
    inputBackground: Color(0xFF293345),
    selectedBackground: Color(0xFF25466E),
    hoverBackground: Color(0xFF30455F),
    online: Color(0xFF4ADE80),
    inUse: Color(0xFFFBBF24),
    offline: Color(0xFF8B96A8),
    notification: Color(0xFFF87171),
    shadow: Color(0x33000000),
    onPrimary: Color(0xFFFFFFFF),
    promoTop: Color(0xFF253A5A),
    promoBottom: Color(0xFF1B3153),
    promoBadge: Color(0xFF38547A),
  );

  /// The extension is registered in both MyTheme modes in common.dart.
  static AdminDeskColors of(BuildContext context) =>
      Theme.of(context).extension<AdminDeskColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AdminDeskColors copyWith({
    Color? primary,
    Color? primaryHover,
    Color? canvas,
    Color? surface,
    Color? sidebar,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? inputBackground,
    Color? selectedBackground,
    Color? hoverBackground,
    Color? online,
    Color? inUse,
    Color? offline,
    Color? notification,
    Color? shadow,
    Color? onPrimary,
    Color? promoTop,
    Color? promoBottom,
    Color? promoBadge,
  }) {
    return AdminDeskColors(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      sidebar: sidebar ?? this.sidebar,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      inputBackground: inputBackground ?? this.inputBackground,
      selectedBackground: selectedBackground ?? this.selectedBackground,
      hoverBackground: hoverBackground ?? this.hoverBackground,
      online: online ?? this.online,
      inUse: inUse ?? this.inUse,
      offline: offline ?? this.offline,
      notification: notification ?? this.notification,
      shadow: shadow ?? this.shadow,
      onPrimary: onPrimary ?? this.onPrimary,
      promoTop: promoTop ?? this.promoTop,
      promoBottom: promoBottom ?? this.promoBottom,
      promoBadge: promoBadge ?? this.promoBadge,
    );
  }

  @override
  AdminDeskColors lerp(ThemeExtension<AdminDeskColors>? other, double t) {
    if (other is! AdminDeskColors) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AdminDeskColors(
      primary: blend(primary, other.primary),
      primaryHover: blend(primaryHover, other.primaryHover),
      canvas: blend(canvas, other.canvas),
      surface: blend(surface, other.surface),
      sidebar: blend(sidebar, other.sidebar),
      border: blend(border, other.border),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      inputBackground: blend(inputBackground, other.inputBackground),
      selectedBackground: blend(selectedBackground, other.selectedBackground),
      hoverBackground: blend(hoverBackground, other.hoverBackground),
      online: blend(online, other.online),
      inUse: blend(inUse, other.inUse),
      offline: blend(offline, other.offline),
      notification: blend(notification, other.notification),
      shadow: blend(shadow, other.shadow),
      onPrimary: blend(onPrimary, other.onPrimary),
      promoTop: blend(promoTop, other.promoTop),
      promoBottom: blend(promoBottom, other.promoBottom),
      promoBadge: blend(promoBadge, other.promoBadge),
    );
  }
}

/// Radius, spacing, borders and shadows used by all new desktop components.
abstract class AdminDeskMetrics {
  static const double sidebarWidth = 200;
  static const double promoWidth = 280;
  static const double minimumDashboardWidth = 900;
  static const double hidePromoBelowWidth = 1160;

  static const double radiusCard = 16;
  static const double radiusControl = 11;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;

  static BorderRadius get cardRadius =>
      BorderRadius.circular(radiusCard);
  static BorderRadius get controlRadius =>
      BorderRadius.circular(radiusControl);

  static List<BoxShadow> cardShadow(AdminDeskColors c) => [
        BoxShadow(
          color: c.shadow,
          offset: const Offset(0, 3),
          blurRadius: 14,
          spreadRadius: 0,
        ),
      ];

  static BoxDecoration cardDecoration(AdminDeskColors c) => BoxDecoration(
        color: c.surface,
        borderRadius: cardRadius,
        border: Border.all(color: c.border),
        boxShadow: cardShadow(c),
      );
}

/// The project already bundles regular/medium/semibold/bold Vazirmatn weights.
/// Avoid w800/w900, which require synthesizing a weight not in pubspec.yaml.
abstract class AdminDeskTypography {
  static const String family = 'Vazirmatn';
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static TextStyle heading(AdminDeskColors c) => TextStyle(
        fontFamily: family,
        fontSize: 20,
        fontWeight: bold,
        color: c.textPrimary,
      );

  static TextStyle title(AdminDeskColors c) => TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: bold,
        color: c.textPrimary,
      );

  static TextStyle body(AdminDeskColors c) => TextStyle(
        fontFamily: family,
        fontSize: 13,
        fontWeight: regular,
        color: c.textPrimary,
      );

  static TextStyle caption(AdminDeskColors c) => TextStyle(
        fontFamily: family,
        fontSize: 11,
        fontWeight: medium,
        color: c.textSecondary,
      );

  static TextStyle identity(AdminDeskColors c) => TextStyle(
        fontFamily: family,
        fontSize: 24,
        fontWeight: bold,
        color: c.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
