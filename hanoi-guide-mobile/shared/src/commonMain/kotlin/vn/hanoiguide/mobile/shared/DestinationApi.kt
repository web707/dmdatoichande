package vn.hanoiguide.mobile.shared

import com.hanoiguide.contracts.DestinationDetail
import com.hanoiguide.contracts.DestinationPage
import io.ktor.client.HttpClient
import io.ktor.client.HttpClientConfig
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.accept
import io.ktor.client.request.get
import io.ktor.client.request.parameter
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.appendPathSegments
import io.ktor.http.isSuccess
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.io.IOException
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json

enum class DestinationFailure {
    Configuration, Network, TimedOut, RateLimited, Unavailable, NotFound, UnexpectedResponse,
}

class DestinationLoadException(val failure: DestinationFailure) : Exception(failure.name)

class DestinationApi internal constructor(
    private val apiOrigin: String,
    private val client: HttpClient,
) : AutoCloseable {
    constructor(apiOrigin: String) : this(apiOrigin, createPlatformHttpClient())

    suspend fun loadPage(query: String, cursor: String?): DestinationPage = getDestination {
        parameter("limit", 20)
        if (query.isNotEmpty()) parameter("q", query)
        if (cursor != null) parameter("cursor", cursor)
    }

    suspend fun loadDetail(id: String): DestinationDetail = getDestination(DestinationFailure.NotFound) {
        url.appendPathSegments(id, encodeSlash = true)
    }

    private suspend inline fun <reified T> getDestination(
        notFound: DestinationFailure = DestinationFailure.UnexpectedResponse,
        configure: HttpRequestBuilder.() -> Unit,
    ): T {
        if (apiOrigin.isBlank()) throw DestinationLoadException(DestinationFailure.Configuration)

        try {
            val response = client.get("${apiOrigin.trimEnd('/')}/api/v1/destinations") {
                accept(ContentType.Application.Json)
                configure()
            }
            if (!response.status.isSuccess()) {
                val failure = when (response.status.value) {
                    404 -> notFound
                    429 -> DestinationFailure.RateLimited
                    in 500..599 -> DestinationFailure.Unavailable
                    else -> DestinationFailure.UnexpectedResponse
                }
                throw DestinationLoadException(failure)
            }
            return withContext(Dispatchers.Default) {
                json.decodeFromString<T>(response.bodyAsText())
            }
        } catch (_: HttpRequestTimeoutException) {
            throw DestinationLoadException(DestinationFailure.TimedOut)
        } catch (_: IOException) {
            throw DestinationLoadException(DestinationFailure.Network)
        } catch (_: SerializationException) {
            throw DestinationLoadException(DestinationFailure.UnexpectedResponse)
        }
    }

    override fun close() = client.close()

    private companion object {
        val json = Json { ignoreUnknownKeys = true }
    }
}

internal fun HttpClientConfig<*>.configureDestinationClient() {
    followRedirects = false
    install(HttpTimeout) {
        connectTimeoutMillis = 4_000
        socketTimeoutMillis = 8_000
        requestTimeoutMillis = 10_000
    }
}

internal expect fun createPlatformHttpClient(): HttpClient
