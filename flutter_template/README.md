# SQL-pancake Flutter (Template)

This folder is a *template* that gets copied into a generated Flutter project.

Use the setup script from the repo root:

- `tools/setup_flutter_app.ps1`

That script will:
- Create `flutter_app/` via `flutter create`
- Copy this template's `lib/` and `assets/` into it
- Add required dependencies (`sqflite`, `path`, `path_provider`)
- Register schema assets

After that:
- `cd flutter_app`
- `flutter run`
- `flutter build apk`
