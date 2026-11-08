import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { cache } from "react";
import { DestinationPhoto } from "@/features/destinations/destination-photo";
import { getDestination } from "@/services/destinations";
import type { DestinationDetail } from "@/services/generated/destinations";

type DetailParams = { params: Promise<{ id: string }> };

const loadDestination = cache(async (id: string) => {
  try {
    return { item: await getDestination(id) };
  } catch {
    return { unavailable: true } as const;
  }
});

const vnd = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" });
const usd = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });

export async function generateMetadata({ params }: DetailParams): Promise<Metadata> {
  const { item } = await loadDestination((await params).id);
  return item ? { title: item.nameVi, description: item.summaryEn } : { title: "Điểm đến" };
}

function sourceLink(value: string) {
  const url = URL.parse(value);
  return url && ["https:", "http:"].includes(url.protocol) && !url.username && !url.password ? url.href : undefined;
}

function mapLink({ latitude, longitude }: DestinationDetail) {
  const url = new URL("https://www.openstreetmap.org/");
  url.searchParams.set("mlat", String(latitude));
  url.searchParams.set("mlon", String(longitude));
  url.hash = `map=17/${latitude}/${longitude}`;
  return url.href;
}

function visitDetails(item: DestinationDetail) {
  const priceUsd = Number(item.ticketPriceUsd);
  const convertedPrice = Number.isFinite(priceUsd) && priceUsd > 0 ? ` · khoảng ${usd.format(priceUsd)} USD` : "";
  const admission = item.ticketPriceVnd > 0 ? `${vnd.format(item.ticketPriceVnd)}${convertedPrice}` : "Miễn phí";
  return [
    { label: "Giờ mở cửa", value: item.openingHours, lang: "en" },
    { label: "Thời điểm tham quan", value: item.bestTimeToVisit, lang: "en" },
    { label: "Vé vào cửa", value: admission },
    { label: "Thời lượng gợi ý", value: item.visitDurationMin > 0 ? `${item.visitDurationMin} phút` : "" },
    { label: "Đặt vé", value: item.bookingInfo, lang: "en" },
  ].filter(({ value }) => value);
}

export default async function DestinationDetailPage({ params }: DetailParams) {
  const { id } = await params;
  const { item, unavailable } = await loadDestination(id);

  if (unavailable) {
    return (
      <div className="message-panel" role="alert">
        <h1 className="text-3xl">Chưa thể tải thông tin điểm đến</h1>
        <p className="mt-2 text-muted">Máy chủ chưa phản hồi hoặc đang gián đoạn.</p>
        <div className="mt-4 flex flex-wrap gap-4">
          <a className="action-button" href={`/destinations/${encodeURIComponent(id)}`}>Thử lại</a>
          <Link className="text-link" href="/destinations" prefetch={false}>Về danh sách điểm đến</Link>
        </div>
      </div>
    );
  }
  if (!item) notFound();

  const source = sourceLink(item.sourceUrl);
  return (
    <article className="mx-auto max-w-5xl">
      <Link className="text-link mb-5" href="/destinations" prefetch={false}>← Danh sách điểm đến</Link>
      <header className="mb-8 border-b border-line pb-6">
        <p className="eyebrow text-accent" lang="en">{item.nameEn}</p>
        <h1 className="mt-2 wrap-break-word text-4xl tracking-tight sm:text-6xl">{item.nameVi}</h1>
        <p className="mt-3 wrap-break-word text-muted">{item.address}</p>
      </header>
      <div className="grid items-start gap-8 lg:grid-cols-[minmax(0,1fr)_21rem]">
        <div>
          <div className="overflow-hidden rounded-2xl border border-line bg-surface pb-3">
            <DestinationPhoto url={item.imageUrl} credit={item.imageCredit} />
          </div>
          <p className="mt-6 wrap-break-word text-lg leading-relaxed" lang="en">{item.summaryEn}</p>
          {item.historyEn && (
            <section className="mt-7">
              <h2 className="text-2xl">Lịch sử</h2>
              <p className="mt-2 wrap-break-word leading-relaxed whitespace-pre-line text-muted" lang="en">{item.historyEn}</p>
            </section>
          )}
          {item.cultureEn && (
            <section className="mt-7">
              <h2 className="text-2xl">Văn hóa và đời sống</h2>
              <p className="mt-2 wrap-break-word leading-relaxed whitespace-pre-line text-muted" lang="en">{item.cultureEn}</p>
            </section>
          )}
          {source && <a className="text-link mt-5" href={source} referrerPolicy="no-referrer">Nguồn thông tin</a>}
        </div>
        <aside className="message-panel" aria-labelledby="visit-title">
          <h2 id="visit-title" className="text-2xl">Thông tin tham quan</h2>
          <dl className="mt-4 grid gap-4">
            {visitDetails(item).map(({ label, value, lang }) => (
              <div key={label}>
                <dt className="text-sm font-semibold text-ink">{label}</dt>
                <dd className="mt-1 wrap-break-word text-sm leading-relaxed text-muted" lang={lang}>{value}</dd>
              </div>
            ))}
            <div>
              <dt className="text-sm font-semibold text-ink">Tọa độ</dt>
              <dd className="mt-1 text-sm text-muted">{item.latitude.toFixed(6)}, {item.longitude.toFixed(6)}</dd>
            </div>
          </dl>
          <a className="text-link mt-4" href={mapLink(item)} referrerPolicy="no-referrer">Xem trên OpenStreetMap</a>
        </aside>
      </div>
    </article>
  );
}
