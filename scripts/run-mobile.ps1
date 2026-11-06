param([string]$DeviceId = 'emulator-5554')
Set-Location (Split-Path $PSScriptRoot -Parent)
flutter run -d $DeviceId --dart-define=API_BASE_URL=http://10.0.2.2:8090
