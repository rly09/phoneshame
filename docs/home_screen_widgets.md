# Home Screen Widgets

This project now pushes a Flutter-owned usage snapshot into native storage so platform home-screen widgets can render it.

## What is implemented

- Flutter computes the widget snapshot in `lib/data/services/home_widget_service.dart`.
- Android has a native home-screen widget provider in `android/app/src/main/kotlin/com/example/phoneshame/RotHomeWidgetProvider.kt`.
- iOS has an app-group bridge in `ios/Runner/AppDelegate.swift`.
- A WidgetKit scaffold lives in `ios/RotWidgetExtension/`.

## Android

1. Run the app once so Flutter syncs widget data.
2. Long-press the home screen and add the `ROT` widget.
3. Tapping the widget opens the Flutter app.

## iOS

The WidgetKit code is present, but the Xcode project still needs the native target and signing setup because that cannot be validated from this Windows workspace.

1. Open `ios/Runner.xcworkspace` in Xcode on macOS.
2. Add a new `Widget Extension` target named `RotWidgetExtension`.
3. Point that target at the files in `ios/RotWidgetExtension/`.
4. Enable `App Groups` for both `Runner` and the new widget target.
5. Use the same group id in both places:
   `group.com.example.phoneshame.widgets`
6. Make sure the widget target is embedded in the app.

## Data contract

These keys are shared between Flutter and native widgets:

- `total_time_label`
- `score`
- `top_app`
- `top_time_label`
- `tracked_apps_count`
- `updated_at_epoch_ms`
- `has_data`
