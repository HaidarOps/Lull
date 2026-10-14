import 'package:flutter/material.dart';

class AppLayout {
  const AppLayout._();

  static const double maxContentWidth = 430;
  static const double pillHeight = 66;
  static const double primaryButtonHeight = 70;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).shortestSide;
    return (width * 0.11).clamp(24.0, 48.0).toDouble();
  }

  static double clampedWidthValue(
    BuildContext context, {
    required double factor,
    required double min,
    required double max,
  }) {
    return (MediaQuery.sizeOf(context).shortestSide * factor)
        .clamp(min, max)
        .toDouble();
  }

  static double clampedHeightValue(
    BuildContext context, {
    required double factor,
    required double min,
    required double max,
  }) {
    return (MediaQuery.sizeOf(context).height * factor)
        .clamp(min, max)
        .toDouble();
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFFCFAF7),
    this.padding,
    this.scrollable = true,
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final pagePadding =
        padding ??
        EdgeInsets.symmetric(horizontal: AppLayout.horizontalPadding(context));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Padding(
              padding: pagePadding,
              child: scrollable
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: child,
                          ),
                        );
                      },
                    )
                  : child,
            ),
          ),
        ),
      ),
    );
  }
}
