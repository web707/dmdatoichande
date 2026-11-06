Set-Location (Split-Path $PSScriptRoot -Parent)
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:8090
