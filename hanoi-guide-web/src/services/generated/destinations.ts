// Generated from openapi/destinations-v1.json. Do not edit.

export interface DestinationSummary {
  id: string;
  nameVi: string;
  nameEn: string;
  summaryEn: string;
  imageUrl: string;
  imageCredit: string;
  address: string;
}

export interface DestinationPage {
  items: DestinationSummary[];
  nextCursor: string | null;
}

export interface DestinationDetail {
  id: string;
  nameVi: string;
  nameEn: string;
  summaryEn: string;
  imageUrl: string;
  imageCredit: string;
  address: string;
  historyEn: string;
  cultureEn: string;
  latitude: number;
  longitude: number;
  sourceUrl: string;
  openingHours: string;
  ticketPriceVnd: number;
  ticketPriceUsd: string;
  bookingInfo: string;
  visitDurationMin: number;
  bestTimeToVisit: string;
}

export interface ApiError {
  error: string;
}
