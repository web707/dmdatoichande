// Generated from openapi/destinations-v1.json. Do not edit.

package com.hanoiguide.contracts

import kotlinx.serialization.Serializable

@Serializable
data class DestinationSummary(
    val id: String,
    val nameVi: String,
    val nameEn: String,
    val summaryEn: String,
    val imageUrl: String,
    val imageCredit: String,
    val address: String,
)

@Serializable
data class DestinationPage(
    val items: List<DestinationSummary>,
    val nextCursor: String?,
)

@Serializable
data class DestinationDetail(
    val id: String,
    val nameVi: String,
    val nameEn: String,
    val summaryEn: String,
    val imageUrl: String,
    val imageCredit: String,
    val address: String,
    val historyEn: String,
    val cultureEn: String,
    val latitude: Double,
    val longitude: Double,
    val sourceUrl: String,
    val openingHours: String,
    val ticketPriceVnd: Int,
    val ticketPriceUsd: String,
    val bookingInfo: String,
    val visitDurationMin: Int,
    val bestTimeToVisit: String,
)

@Serializable
data class ApiError(
    val error: String,
)
