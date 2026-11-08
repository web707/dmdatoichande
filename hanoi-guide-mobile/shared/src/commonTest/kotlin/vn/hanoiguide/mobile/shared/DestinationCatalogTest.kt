package vn.hanoiguide.mobile.shared

import com.hanoiguide.contracts.DestinationPage
import com.hanoiguide.contracts.DestinationSummary
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class DestinationCatalogTest {
    @Test
    fun loadsAndAppendsPagesWithTheSameSearch() = runTest {
        val requests = mutableListOf<Pair<String, String?>>()
        val catalog = DestinationCatalog(this) { query, cursor ->
            requests.add(query to cursor)
            when {
                query.isEmpty() -> DestinationPage(emptyList(), null)
                cursor == null -> DestinationPage(listOf(destination("first")), "second-page")
                else -> DestinationPage(listOf(destination("first"), destination("second")), null)
            }
        }

        assertTrue(catalog.state.value.loading)
        advanceUntilIdle()
        catalog.search("  Hà Nội ")
        advanceUntilIdle()
        catalog.loadMore()
        catalog.loadMore()
        advanceUntilIdle()

        assertEquals(listOf("" to null, "Hà Nội" to null, "Hà Nội" to "second-page"), requests)
        assertEquals(listOf("first", "second"), catalog.state.value.items.map { it.id })
        assertFalse(catalog.state.value.hasMore)
    }

    @Test
    fun retriesAPageWithoutDiscardingVisibleResults() = runTest {
        var attempts = 0
        val catalog = DestinationCatalog(this) { _, cursor ->
            when {
                cursor == null -> DestinationPage(listOf(destination("first")), "second-page")
                ++attempts == 1 -> throw DestinationLoadException(DestinationFailure.Unavailable)
                else -> DestinationPage(listOf(destination("second")), null)
            }
        }

        advanceUntilIdle()
        catalog.loadMore()
        advanceUntilIdle()
        assertEquals(DestinationFailure.Unavailable, catalog.state.value.failure)
        assertEquals(listOf("first"), catalog.state.value.items.map { it.id })
        catalog.retry()
        advanceUntilIdle()

        assertEquals(2, attempts)
        assertEquals(listOf("first", "second"), catalog.state.value.items.map { it.id })
        assertEquals(null, catalog.state.value.failure)
    }

    @Test
    fun cancelsAnObsoleteRequestWhenSearchChanges() = runTest {
        val oldPage = CompletableDeferred<DestinationPage>()
        val catalog = DestinationCatalog(this) { query, _ ->
            if (query.isEmpty()) oldPage.await()
            else DestinationPage(listOf(destination("new")), null)
        }

        runCurrent()
        catalog.search("new")
        advanceUntilIdle()
        oldPage.complete(DestinationPage(listOf(destination("old")), null))
        advanceUntilIdle()

        assertEquals(listOf("new"), catalog.state.value.items.map { it.id })
        assertEquals(null, catalog.state.value.failure)
    }

    private fun destination(id: String) = DestinationSummary(
        id = id,
        nameVi = "Hà Nội",
        nameEn = "Hanoi",
        summaryEn = "Explore Hanoi.",
        imageUrl = "",
        imageCredit = "",
        address = "Hà Nội",
    )
}
