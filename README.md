# BSN Path Pakistan

BSN Path Pakistan is an offline-first learning platform for students enrolled in Pakistan's four-year Generic BSN programme. This repository contains the Flutter student application, the browser owner dashboard, shared content contracts, and the Vertex AI content-production service.

## Safety state

The repository is an internal beta. Production purchases are disabled. AI-generated clinical, pharmacology, calculation, emergency, and patient-safety content cannot be published until the owner approves it.

## Workspace

- `work/student_app`: Flutter Android student app and Flutter Web owner dashboard.
- `work/content`: versioned curriculum, sources, and representative content packages.
- `work/services`: server-side content generation and package validation.
- `docs`: operating, security, and deployment instructions.

## Local commands

```powershell
$flutter = 'C:\Users\kalho\Documents\Codex\tools\flutter\bin\flutter.bat'
& $flutter pub get --directory work\student_app
& $flutter test work\student_app
& $flutter run --directory work\student_app
& $flutter run --directory work\student_app -d chrome --target lib/main_admin.dart
```

Cloud credentials must never be committed or embedded in the client. See `docs/SETUP.md`.
