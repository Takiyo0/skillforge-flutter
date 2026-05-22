import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skillforgeapp/ui/shell_header_state.dart';

class AppColors {
  static const lightForeground = Color(0xFF0F172A);
  static const darkForeground = Color(0xFFF1F5F9);
  static const primaryBlue = Color(0xFF2563EB);
  static const cyan = Color(0xFF0EA5E9);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FBFF),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionsBuilder(),
          TargetPlatform.iOS: _NoTransitionsBuilder(),
          TargetPlatform.macOS: _NoTransitionsBuilder(),
          TargetPlatform.windows: _NoTransitionsBuilder(),
          TargetPlatform.linux: _NoTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        primary: AppColors.primaryBlue,
        brightness: Brightness.light,
      ),
      textTheme: _textTheme(base.textTheme, Brightness.light),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.68),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: _dialogTheme(Brightness.light),
      snackBarTheme: _snackBarTheme(Brightness.light),
      inputDecorationTheme: _inputTheme(Brightness.light),
      chipTheme: _chipTheme(Brightness.light),
      dividerTheme: DividerThemeData(
        color: Colors.blue.withValues(alpha: 0.15),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF020817),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionsBuilder(),
          TargetPlatform.iOS: _NoTransitionsBuilder(),
          TargetPlatform.macOS: _NoTransitionsBuilder(),
          TargetPlatform.windows: _NoTransitionsBuilder(),
          TargetPlatform.linux: _NoTransitionsBuilder(),
          TargetPlatform.fuchsia: _NoTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
      ),
      textTheme: _textTheme(base.textTheme, Brightness.dark),
      cardTheme: CardThemeData(
        color: const Color(0xFF0F172A).withValues(alpha: 0.68),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: _dialogTheme(Brightness.dark),
      snackBarTheme: _snackBarTheme(Brightness.dark),
      inputDecorationTheme: _inputTheme(Brightness.dark),
      chipTheme: _chipTheme(Brightness.dark),
      dividerTheme: DividerThemeData(
        color: Colors.lightBlueAccent.withValues(alpha: 0.18),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme theme, Brightness mode) {
    final fg = mode == Brightness.dark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    return theme.copyWith(
      headlineLarge: theme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: fg,
      ),
      headlineMedium: theme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        color: fg,
      ),
      headlineSmall: theme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: fg,
      ),
      titleLarge: theme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: fg,
      ),
      titleMedium: theme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: fg,
      ),
      bodyLarge: theme.bodyLarge?.copyWith(color: fg),
      bodyMedium: theme.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.88)),
    );
  }

  static InputDecorationTheme _inputTheme(Brightness mode) {
    final borderColor = const Color(
      0xFF60A5FA,
    ).withValues(alpha: mode == Brightness.dark ? 0.24 : 0.26);
    return InputDecorationTheme(
      filled: true,
      fillColor: mode == Brightness.dark
          ? const Color(0xFF020617).withValues(alpha: 0.62)
          : Colors.white.withValues(alpha: 0.70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static ChipThemeData _chipTheme(Brightness mode) {
    return ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: const Color(0xFF60A5FA).withValues(alpha: 0.22)),
      backgroundColor: mode == Brightness.dark
          ? const Color(0xFF0F172A).withValues(alpha: 0.54)
          : Colors.white.withValues(alpha: 0.62),
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: mode == Brightness.dark
            ? AppColors.darkForeground
            : AppColors.lightForeground,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(Brightness mode) {
    final isDark = mode == Brightness.dark;
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.96)
          : const Color(0xFF0F172A).withValues(alpha: 0.92),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static DialogThemeData _dialogTheme(Brightness mode) {
    final isDark = mode == Brightness.dark;
    return DialogThemeData(
      backgroundColor: isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.96)
          : Colors.white.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: _textTheme(
        ThemeData(brightness: mode).textTheme,
        mode,
      ).titleLarge,
      contentTextStyle: _textTheme(
        ThemeData(brightness: mode).textTheme,
        mode,
      ).bodyMedium,
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF020817), Color(0xFF07101D), Color(0xFF02050C)]
              : const [Color(0xFFF8FBFF), Color(0xFFEEF6FF), Color(0xFFE2F0FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _orb(
              const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.24 : 0.18),
              260,
            ),
          ),
          Positioned(
            top: -70,
            right: -40,
            child: _orb(
              const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.22 : 0.16),
              220,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class AppRouteSurface extends StatelessWidget {
  const AppRouteSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF020817), Color(0xFF07101D), Color(0xFF02050C)]
              : const [Color(0xFFF8FBFF), Color(0xFFEEF6FF), Color(0xFFE2F0FF)],
        ),
      ),
      child: child,
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: const Color(
                0xFF60A5FA,
              ).withValues(alpha: isDark ? 0.2 : 0.18),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF0F172A).withValues(alpha: 0.86),
                      const Color(0xFF0F172A).withValues(alpha: 0.62),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF020617) : const Color(0xFF1E293B))
                        .withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

typedef AppBottomSheetBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? barrierLabel,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: isDark
        ? Colors.black.withValues(alpha: 0.72)
        : const Color(0xFF0F172A).withValues(alpha: 0.44),
    builder: builder,
  );
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required AppBottomSheetBuilder builder,
  double minChildSize = 0.35,
  double initialChildSize = 0.72,
  double maxChildSize = 0.90,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final isDark = theme.brightness == Brightness.dark;
      return DraggableScrollableSheet(
        expand: false,
        minChildSize: minChildSize,
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color:
                  theme.bottomSheetTheme.backgroundColor ??
                  (isDark ? const Color(0xFF0F172A) : Colors.white),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: const Color(
                  0xFF60A5FA,
                ).withValues(alpha: isDark ? 0.18 : 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (showDragHandle)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  Expanded(child: builder(sheetContext, scrollController)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class AppChromeMetrics {
  static const mobileOverlayMargin = 18.0;

  static const mobileTopBarPanelHeight = 24.0;
  static const mobileBottomBarPanelHeight = 88.0;
  static const mobileTopContentGap = 12.0;
  static const bottomContentInsetFallback =
      mobileOverlayMargin + mobileBottomBarPanelHeight;

  static double topContentInset(BuildContext context) {
    return MediaQuery.paddingOf(context).top +
        mobileOverlayMargin +
        mobileTopBarPanelHeight +
        mobileTopContentGap;
  }

  static double bottomContentInset(BuildContext context) {
    return bottomContentInsetFallback;
  }
}

final shellHeaderProvider = StateProvider<ShellHeaderData>(
  (_) => const ShellHeaderData(title: ''),
);

class AppPage extends ConsumerStatefulWidget {
  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  ConsumerState<AppPage> createState() => _AppPageState();
}

class _AppPageState extends ConsumerState<AppPage> {
  void _syncHeaderIfCurrent() {
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) return;

    final nextHeader = ShellHeaderData(
      title: widget.title,
      subtitle: widget.subtitle,
    );
    final currentHeader = ref.read(shellHeaderProvider);
    if (currentHeader != nextHeader) {
      ref.read(shellHeaderProvider.notifier).state = nextHeader;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncHeaderIfCurrent();
    });
  }

  @override
  void didUpdateWidget(covariant AppPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.subtitle != widget.subtitle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncHeaderIfCurrent();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 0,
        left: AppChromeMetrics.mobileOverlayMargin,
        right: AppChromeMetrics.mobileOverlayMargin,
        top: 0,
      ),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: SizedBox(height: AppChromeMetrics.topContentInset(context)),
          ),
        ],
        body: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            final extraBottomInset = AppChromeMetrics.bottomContentInset(
              context,
            );
            return MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  bottom: media.padding.bottom + extraBottomInset,
                ),
                viewPadding: media.viewPadding.copyWith(
                  bottom: media.viewPadding.bottom + extraBottomInset,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppAsyncState {
  static Widget loading() => const Center(child: CircularProgressIndicator());

  static Widget error(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

class AppToast {
  static OverlayEntry? _activeEntry;

  static String errorMessage(Object error) {
    String fromDynamic(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      if (value is List) {
        final parts = value
            .map(fromDynamic)
            .where((v) => v.isNotEmpty)
            .toList();
        return parts.join('\n').trim();
      }
      if (value is Map) {
        final map = value.map((key, val) => MapEntry(key.toString(), val));
        final nested = map['message'] ?? map['error'] ?? map['detail'];
        if (nested != null) {
          final extracted = fromDynamic(nested);
          if (extracted.isNotEmpty) return extracted;
        }
        return jsonEncode(map);
      }
      return '';
    }

    final direct = fromDynamic(error);
    if (direct.isNotEmpty) return direct;

    try {
      final dynamic dyn = error;
      final fromField = fromDynamic(dyn.message);
      if (fromField.isNotEmpty) return fromField;
    } catch (_) {}

    final raw = error.toString().trim();
    if (raw.isNotEmpty) return raw;
    return 'Unexpected error';
  }

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _activeEntry?.remove();
    _activeEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (toastContext) {
        final media = MediaQuery.of(toastContext);
        final bottomInset = media.viewInsets.bottom > 0
            ? media.viewInsets.bottom
            : media.padding.bottom;
        final bottomOffset = bottomInset + 12;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomOffset,
                child: Material(
                  color: Colors.transparent,
                  elevation: 9999,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
    Future<void>.delayed(duration, () {
      if (_activeEntry == entry) {
        entry.remove();
        _activeEntry = null;
      }
    });
  }

  static void showError(
    BuildContext context,
    Object error, {
    String? prefix,
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = errorMessage(error);
    show(
      context,
      prefix == null || prefix.trim().isEmpty ? message : '$prefix: $message',
      duration: duration,
    );
  }
}

void showAppTopToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  Color? backgroundColor,
}) {
  AppToast.show(context, message, duration: duration);
}
