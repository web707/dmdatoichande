package vn.hanoiguide.mobile.shared

import com.hanoiguide.contracts.DestinationPage
import com.hanoiguide.contracts.DestinationSummary
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class DestinationCatalogState(
    val query: String = "",
    val items: List<DestinationSummary> = emptyList(),
    val loading: Boolean = false,
    val hasMore: Boolean = false,
    val failure: DestinationFailure? = null,
)

// Call screen actions from the same UI dispatcher as the scope.
class DestinationCatalog(
    private val scope: CoroutineScope,
    private val loadPage: suspend (query: String, cursor: String?) -> DestinationPage,
) {
    private val mutableState = MutableStateFlow(DestinationCatalogState())
    val state = mutableState.asStateFlow()
    private var nextCursor: String? = null
    private var request: Job? = null

    init {
        search("")
    }

    fun search(input: String) {
        val query = input.trim()
        if (mutableState.value.loading && mutableState.value.query == query) return

        request?.cancel()
        nextCursor = null
        load(DestinationCatalogState(query = query), null)
    }

    fun loadMore() {
        val current = mutableState.value
        val cursor = nextCursor ?: return
        if (!current.loading) load(current, cursor)
    }

    fun retry() {
        val current = mutableState.value
        if (current.failure != null) load(current, nextCursor)
    }

    private fun load(current: DestinationCatalogState, cursor: String?) {
        mutableState.value = current.copy(loading = true, failure = null)
        request = scope.launch {
            try {
                val page = loadPage(current.query, cursor)
                currentCoroutineContext().ensureActive()
                nextCursor = page.nextCursor
                val items = (current.items + page.items).distinctBy { it.id }
                mutableState.value = current.copy(items = items, hasMore = nextCursor != null, failure = null)
            } catch (failure: DestinationLoadException) {
                currentCoroutineContext().ensureActive()
                mutableState.value = current.copy(failure = failure.failure)
            }
        }
    }
}
