package vn.hanoiguide.mobile.shared

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class DestinationApiTest {
    @Test
    fun readsTheVersionedContractAndEncodesQueryParameters() = runTest {
        val engine = MockEngine { request ->
            assertEquals("/api/v1/destinations", request.url.encodedPath)
            assertEquals("Hồ Gươm & Hà Nội", request.url.parameters["q"])
            assertEquals("opaque-cursor", request.url.parameters["cursor"])
            assertEquals("20", request.url.parameters["limit"])
            respond(
                """{"items":[{"id":"658c8d41-e6a8-48fa-93ca-54fa568cc2ac","nameVi":"Hồ Gươm","nameEn":"Sword Lake","summaryEn":"","imageUrl":"","imageCredit":"","address":"Hà Nội","addedLater":true}],"nextCursor":null}""",
            )
        }

        DestinationApi("https://guide.example", HttpClient(engine)).use { api ->
            val page = api.loadPage("Hồ Gươm & Hà Nội", "opaque-cursor")
            assertEquals("Hồ Gươm", page.items.single().nameVi)
            assertNull(page.nextCursor)
        }
    }

    @Test
    fun mapsHttpFailuresToSafeUiStates() = runTest {
        val engine = MockEngine { respond("proxy response", HttpStatusCode.ServiceUnavailable) }

        DestinationApi("https://guide.example", HttpClient(engine)).use { api ->
            val failure = assertFailsWith<DestinationLoadException> { api.loadPage("", null) }
            assertEquals(DestinationFailure.Unavailable, failure.failure)
        }
    }

    @Test
    fun rejectsMalformedContractData() = runTest {
        val engine = MockEngine { respond("""{"items":[]}""") }

        DestinationApi("https://guide.example", HttpClient(engine)).use { api ->
            val failure = assertFailsWith<DestinationLoadException> { api.loadPage("", null) }
            assertEquals(DestinationFailure.UnexpectedResponse, failure.failure)
        }
    }

    @Test
    fun readsDetailById() = runTest {
        val id = "658c8d41-e6a8-48fa-93ca-54fa568cc2ac"
        val engine = MockEngine { request ->
            assertEquals("/api/v1/destinations/$id", request.url.encodedPath)
            assertNull(request.url.parameters["limit"])
            respond(
                """{"id":"$id","nameVi":"Hồ Gươm","nameEn":"Sword Lake","summaryEn":"","imageUrl":"","imageCredit":"","address":"Hà Nội","historyEn":"","cultureEn":"","latitude":21.0287,"longitude":105.8522,"sourceUrl":"","openingHours":"Always open","ticketPriceVnd":0,"ticketPriceUsd":"0","bookingInfo":"","visitDurationMin":30,"bestTimeToVisit":"Evening"}""",
            )
        }

        DestinationApi("https://guide.example", HttpClient(engine)).use { api ->
            val detail = api.loadDetail(id)
            assertEquals(id, detail.id)
            assertEquals(21.0287, detail.latitude)
            assertEquals(30, detail.visitDurationMin)
        }
    }

    @Test
    fun mapsDeletedDetailToNotFound() = runTest {
        val engine = MockEngine { respond("""{"error":"Destination not found."}""", HttpStatusCode.NotFound) }

        DestinationApi("https://guide.example", HttpClient(engine)).use { api ->
            val failure = assertFailsWith<DestinationLoadException> {
                api.loadDetail("658c8d41-e6a8-48fa-93ca-54fa568cc2ac")
            }
            assertEquals(DestinationFailure.NotFound, failure.failure)
        }
    }
}
