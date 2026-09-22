## 2.0.0

- Raise the Dart SDK constraint from `^3.6.2` to `^3.11.0`. This is the
  breaking part of the release: the package itself is source-compatible, but
  consumers on an older SDK can no longer resolve it. The floor is what the
  upgraded dev dependencies require, and it stays below the Dart 3.13 bundled
  with the Flutter version the Stift app pins.
- Upgrade `lints` to `^6.0.0` and `test` to `^1.25.0`.
- Remove `publisher` from `pubspec.yaml`. It is not a key pub recognises —
  the verified publisher is configured on pub.dev, not in the manifest — and
  `dart pub publish` warned about it on every run.
- Reformat with the current `dart format` style, selected by the new SDK
  floor. No behaviour change.

## 1.0.0

- Initial version.
