"use client";

import { useLinkStatus } from "next/link";

export function DestinationLinkStatus() {
  const { pending } = useLinkStatus();
  return <span role="status" className="block min-h-4 text-xs text-muted">{pending ? "Đang mở điểm đến…" : ""}</span>;
}
