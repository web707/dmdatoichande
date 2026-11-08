package vn.hanoiguide.mobile.compose

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.hanoiguide.contracts.DestinationDetail
import vn.hanoiguide.mobile.shared.DestinationFailure

internal sealed interface DestinationDetailState {
    data object Loading : DestinationDetailState
    data class Ready(val destination: DestinationDetail) : DestinationDetailState
    data class Failed(val failure: DestinationFailure) : DestinationDetailState
}

@Composable
internal fun DestinationDetailScreen(
    state: DestinationDetailState,
    onBack: () -> Unit,
    retry: () -> Unit,
) {
    Column(Modifier.widthIn(max = 760.dp).fillMaxSize().padding(horizontal = 20.dp)) {
        TextButton(onClick = onBack) { Text("Back to destinations") }
        when (state) {
            DestinationDetailState.Loading -> LoadingStatus("Loading destination…")
            is DestinationDetailState.Failed -> FailureStatus(state.failure, retry)
            is DestinationDetailState.Ready -> DestinationInformation(state.destination)
        }
    }
}

@Composable
private fun DestinationInformation(destination: DestinationDetail) {
    Column(
        modifier = Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(destination.nameVi.ifBlank { destination.nameEn }, style = MaterialTheme.typography.headlineLarge)
            if (destination.nameEn.isNotBlank() && destination.nameEn != destination.nameVi) {
                Text(destination.nameEn, style = MaterialTheme.typography.titleMedium)
            }
            if (destination.summaryEn.isNotBlank()) Text(destination.summaryEn)
        }

        DetailSection("Address", destination.address)
        DetailSection("Opening hours", destination.openingHours)
        DetailSection("Admission", "${destination.ticketPriceVnd} VND")
        DetailSection("Typical visit", "${destination.visitDurationMin} min")
        DetailSection("Best time to visit", destination.bestTimeToVisit)
        DetailSection("Booking", destination.bookingInfo)
        DetailSection("Coordinates", "${destination.latitude}, ${destination.longitude}")
        DetailSection("History", destination.historyEn)
        DetailSection("Culture", destination.cultureEn)
    }
}

@Composable
private fun DetailSection(title: String, content: String) {
    if (content.isBlank()) return
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        Text(content, style = MaterialTheme.typography.bodyMedium)
    }
}
