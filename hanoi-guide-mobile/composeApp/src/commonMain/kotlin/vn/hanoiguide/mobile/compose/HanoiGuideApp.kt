package vn.hanoiguide.mobile.compose

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.hanoiguide.contracts.DestinationSummary
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import vn.hanoiguide.mobile.shared.DestinationApi
import vn.hanoiguide.mobile.shared.DestinationCatalog
import vn.hanoiguide.mobile.shared.DestinationCatalogState
import vn.hanoiguide.mobile.shared.DestinationFailure
import vn.hanoiguide.mobile.shared.DestinationLoadException

private val lightScheme = lightColorScheme(primary = Color(0xFF23634A))
private val darkScheme = darkColorScheme(primary = Color(0xFF90D5AF))

@Composable
fun HanoiGuideApp(apiOrigin: String) {
    val model = viewModel(key = apiOrigin) { CatalogViewModel(DestinationApi(apiOrigin)) }
    val state by model.catalog.state.collectAsStateWithLifecycle()
    val detail by model.detail.collectAsStateWithLifecycle()
    val catalogStateHolder = rememberSaveableStateHolder()
    NavigationBackHandler(
        state = rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled = detail != null,
        onBackCompleted = model::closeDetail,
    )

    MaterialTheme(colorScheme = if (isSystemInDarkTheme()) darkScheme else lightScheme) {
        Scaffold { insets ->
            Box(
                modifier = Modifier.fillMaxSize().padding(insets).imePadding(),
                contentAlignment = Alignment.TopCenter,
            ) {
                val currentDetail = detail
                if (currentDetail == null) {
                    catalogStateHolder.SaveableStateProvider("catalog") {
                        DestinationScreen(state, model.catalog, model::openDetail)
                    }
                } else {
                    DestinationDetailScreen(currentDetail, model::closeDetail, model::retryDetail)
                }
            }
        }
    }
}

private class CatalogViewModel(private val api: DestinationApi) : ViewModel() {
    val catalog = DestinationCatalog(viewModelScope, api::loadPage)
    private val mutableDetail = MutableStateFlow<DestinationDetailState?>(null)
    val detail = mutableDetail.asStateFlow()
    private var detailId: String? = null
    private var detailRequest: Job? = null

    fun openDetail(id: String) {
        if (detailId == id && mutableDetail.value == DestinationDetailState.Loading) return
        detailRequest?.cancel()
        detailId = id
        mutableDetail.value = DestinationDetailState.Loading
        detailRequest = viewModelScope.launch {
            try {
                val result = api.loadDetail(id)
                ensureActive()
                mutableDetail.value = DestinationDetailState.Ready(result)
            } catch (failure: DestinationLoadException) {
                ensureActive()
                mutableDetail.value = DestinationDetailState.Failed(failure.failure)
            }
        }
    }

    fun retryDetail() {
        detailId?.let(::openDetail)
    }

    fun closeDetail() {
        detailRequest?.cancel()
        detailRequest = null
        detailId = null
        mutableDetail.value = null
    }

    override fun onCleared() = api.close()
}

@Composable
private fun DestinationScreen(
    state: DestinationCatalogState,
    catalog: DestinationCatalog,
    openDetail: (String) -> Unit,
) {
    var input by rememberSaveable(state.query) { mutableStateOf(state.query) }
    val focusManager = LocalFocusManager.current
    val submitSearch = {
        focusManager.clearFocus()
        catalog.search(input)
    }

    Column(Modifier.widthIn(max = 760.dp).fillMaxSize()) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text("Hanoi Guide", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
            Text("Explore Hanoi", style = MaterialTheme.typography.headlineLarge)
            OutlinedTextField(
                value = input,
                onValueChange = { if (it.length <= 100) input = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Search destinations") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { submitSearch() }),
            )
            Button(onClick = submitSearch) { Text("Search") }
        }

        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(state.items, key = { it.id }, contentType = { "destination" }) { destination ->
                DestinationCard(destination) { openDetail(destination.id) }
            }
            item("status") {
                val failure = state.failure
                when {
                    state.loading -> LoadingStatus()
                    failure != null -> FailureStatus(failure, catalog::retry)
                    state.items.isEmpty() -> Text("No destinations found.", modifier = Modifier.semantics {
                        liveRegion = LiveRegionMode.Polite
                    })
                    state.hasMore -> Button(onClick = catalog::loadMore) { Text("Load more") }
                }
            }
        }
    }
}

@Composable
private fun DestinationCard(destination: DestinationSummary, openDetail: () -> Unit) {
    Card(onClick = openDetail, modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(
                destination.nameVi.ifBlank { destination.nameEn },
                style = MaterialTheme.typography.titleLarge,
            )
            if (destination.nameEn.isNotBlank() && destination.nameEn != destination.nameVi) {
                Text(destination.nameEn, style = MaterialTheme.typography.titleSmall)
            }
            if (destination.address.isNotBlank()) {
                Text(destination.address, style = MaterialTheme.typography.bodySmall)
            }
            if (destination.summaryEn.isNotBlank()) {
                Text(destination.summaryEn, style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Composable
internal fun LoadingStatus(message: String = "Loading destinations…") {
    Column(
        modifier = Modifier.fillMaxWidth().padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        CircularProgressIndicator()
        Text(message, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
    }
}

@Composable
internal fun FailureStatus(failure: DestinationFailure, retry: () -> Unit) {
    val message = when (failure) {
        DestinationFailure.Configuration -> "The guide server address is missing from this build."
        DestinationFailure.Network -> "Check your connection and try again."
        DestinationFailure.TimedOut -> "The guide server took too long to respond."
        DestinationFailure.RateLimited -> "Too many requests. Wait a moment and try again."
        DestinationFailure.Unavailable -> "The guide server is temporarily unavailable."
        DestinationFailure.NotFound -> "This destination is no longer available."
        DestinationFailure.UnexpectedResponse -> "The guide server returned an unexpected response."
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            message,
            color = MaterialTheme.colorScheme.error,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
        )
        if (failure != DestinationFailure.Configuration && failure != DestinationFailure.NotFound) {
            Button(onClick = retry) { Text("Retry") }
        }
    }
}
