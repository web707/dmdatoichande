param([string]$DeviceId = 'emulator-5554', [switch]$Profile)
Set-Location (Split-Path $PSScriptRoot -Parent)
if ($Profile) {
    flutter run --profile -d $DeviceId --dart-define=API_BASE_URL=http://10.0.2.2:8090
} else {
    flutter run -d $DeviceId --dart-define=API_BASE_URL=http://10.0.2.2:8090
}
