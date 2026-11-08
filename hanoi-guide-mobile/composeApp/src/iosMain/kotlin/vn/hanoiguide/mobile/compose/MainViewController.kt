package vn.hanoiguide.mobile.compose

import androidx.compose.ui.window.ComposeUIViewController

fun MainViewController(apiOrigin: String) = ComposeUIViewController {
    HanoiGuideApp(apiOrigin)
}
