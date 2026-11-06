$travelEnv = @{
    PUB_CACHE = 'D:\android-tools\pub-cache'
    GRADLE_USER_HOME = 'D:\android-tools\gradle-home'
    ANDROID_HOME = 'D:\android-tools\sdk'
    ANDROID_AVD_HOME = 'D:\android-tools\avd'
    ANDROID_USER_HOME = 'D:\android-tools\android-user'
    ANDROID_EMULATOR_HOME = 'D:\android-tools\android-user'
}
foreach ($entry in $travelEnv.GetEnumerator()) {
    New-Item -ItemType Directory -Force -Path $entry.Value | Out-Null
    [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'User')
    Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value
}
Write-Host 'Flutter/Android caches and AVD paths point to drive D. Restart other terminals to inherit these variables.'
