# Project Instructions

## Responsive UI Rules

- Treat every Flutter screen as responsive by default across small phones, large phones, tablets, dynamic text, and safe-area differences.
- Use shared responsive primitives from `lib/shared/app_layout.dart` for page padding, max content width, scroll fallback, and clamped sizing.
- New full-screen app pages should use `ResponsivePage` unless they have a custom full-bleed animation or image scene.
- Avoid rigid vertical `Column` layouts that depend on exact device height. If a page has multiple fixed-height elements, make it scroll-safe.
- Use `AppLayout.clampedWidthValue` and `AppLayout.clampedHeightValue` instead of raw viewport math scattered through screens.
- Keep primary action buttons reachable on short screens; content may scroll, but buttons should not overflow.
- Before finishing UI work, run `dart format lib` and `flutter analyze`, and test mentally against iPhone SE, standard iPhone, large iPhone, and tablet widths.

## Design Consistency

- Prefer shared components in `lib/shared/app_components.dart` for repeated controls such as primary buttons and option pills.
- Keep meditation UI calm: soft colors, generous spacing, rounded controls, restrained motion, and no abrupt animation resets.
- If a screen needs custom animation, keep layout and controls responsive around the animation.
