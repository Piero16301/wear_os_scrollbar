## 1.1.1

* **Testing & Quality:**
  * Achieved 100% test coverage across the entire package (`369 of 369 lines`).
  * Added widget tests covering edge cases: rotary velocity tracking gesture threshold reset, fling simulation cancellation upon incoming rotary events, fallback to `ClampingScrollSimulation` when scroll physics returns null, ticker recovery on fling timeout, and upper boundary limit haptics.

## 1.1.0

* **New Feature - Native Wear OS 7 Fling Physics:**
  * Added `enableFling` and `flingFactor` to support natural ballistic momentum and friction decay when spinning the rotary input quickly.
* **Fix - Single Boundary Limit Haptic:**
  * Fixed repetitive vibrations at list boundaries: limit haptic now triggers only once upon reaching the start or end, silencing further rotation until scrolling away.
* **New Feature - Route Navigation Isolation:**
  * Added `onlyWhenCurrentRoute` to restrict rotary input strictly to the active foreground route, preserving scroll positions when navigating between pages.
* **Testing:**
  * Added unit and widget tests for fling inertia, boundary haptic silencing, and navigation isolation.

## 1.0.0

* **New Feature - Native Wear OS Rotary Haptics:**
  * Added native crown tactile feedback with `WearOsHapticFeedback.rotaryTick` (using Android's `ROTARY_SCROLL_TICK` and `ROTARY_SCROLL_LIMIT`).
  * Added `enableLimitHaptic` to signal boundary collisions at the top/bottom of lists.
* **Improvement - Smooth Continuous Rotary Scrolling:**
  * Added `enableSmoothScroll` with exponential decay interpolation and `rotarySensitivity` for calibrated, fluid crown navigation.
  * Added touch interruption to smoothly stop active rotary animations on user drag.
* **Compatibility & Testing:**
  * Updated `material_ui` dependency to `^1.1.1` and added comprehensive unit and widget tests.

## 0.2.2

* **Fix:** Migrates `WearOsExpressiveItem` and `WearOsScrollbar` from deprecated `material` widgets to new `material_ui` package, ensuring compatibility with the latest Flutter Wear OS SDK (3.47+).

## 0.2.1

* **Fix:** `WearOsExpressiveItem` now wraps the scaled widget in an `Align` with `heightFactor` equal to the current scale, so the layout space shrinks proportionally to the visual size and the gap between list items remains consistent regardless of their position in the viewport.
* **Improvement:** Scale reduction in `WearOsExpressiveItem` is now limited to the outer 25% at the top and bottom of the viewport. The central 50% always displays items at `maxScale`, and the easing curve is only applied within the edge zones.

## 0.2.0

* **New Feature:** Added `WearOsExpressiveItem` widget to support Material 3 Expressive scrolling aesthetics (dynamic fisheye scaling effect based on scroll position).
* Exported the new widget from the main library to make it publicly accessible.
* Added comprehensive unit and widget tests for the new feature, maintaining 100% test coverage across the package.
* Updated example application to demonstrate `WearOsExpressiveItem` usage with a list of tiles.

## 0.1.1

* Updates minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Migrates to use the built-in Kotlin DSL for Android Gradle.

## 0.1.0

* Added `hideIndicator` parameter to `WearOsScrollbar` to allow hiding the visual indicator while maintaining rotary input and haptic feedback.
* Improved compatibility with `PageView` by allowing custom page indicators.
* Added widget tests for the new `hideIndicator` functionality.

## 0.0.4

* Updated documentation and added examples.

## 0.0.3

* Fixed missing documentation for `MethodChannelWearOsScrollbar` constructor to achieve 100% pub.dev score.

## 0.0.2

* Added complete public API documentation for pub.dev compliance.

## 0.0.1

* Initial release.
