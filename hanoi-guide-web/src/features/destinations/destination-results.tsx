import Link from "next/link";
import { Card, CardContent } from "@/components/ui/card";
import { getDestinations } from "@/services/destinations";
import type { DestinationPage, DestinationSummary } from "@/services/generated/destinations";
import { DestinationLinkStatus } from "./destination-link-status";
import { DestinationPhoto } from "./destination-photo";

const grid = "grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3";

export function destinationHref(query: string, cursor = "") {
  const params = new URLSearchParams();
  if (query) params.set("q", query);
  if (cursor) params.set("cursor", cursor);
  return params.size ? `/destinations?${params}` : "/destinations";
}

function DestinationCard({ item }: { item: DestinationSummary }) {
  return (
    <Card className="h-full" data-destination-id={item.id}>
      <DestinationPhoto url={item.imageUrl} credit={item.imageCredit} />
      <CardContent>
        <Link className="inline-block hover:text-accent hover:underline underline-offset-4" href={`/destinations/${encodeURIComponent(item.id)}`} prefetch={false}>
          <h3 className="wrap-break-word text-2xl leading-tight">{item.nameVi}</h3>
          <DestinationLinkStatus />
        </Link>
        <p className="mt-1 wrap-break-word text-sm text-muted" lang="en">{item.nameEn}</p>
        <p className="mt-4 line-clamp-3 wrap-break-word text-sm leading-relaxed" lang="en">{item.summaryEn}</p>
        <p className="mt-4 border-t border-line pt-3 wrap-break-word text-sm font-medium text-accent">{item.address}</p>
      </CardContent>
    </Card>
  );
}

export async function DestinationResults({ query, cursor }: { query: string; cursor: string }) {
  let page: DestinationPage;
  try {
    page = await getDestinations(query, cursor);
  } catch {
    return (
      <div className="message-panel" role="alert">
        <h3 className="text-2xl">Chưa thể tải điểm đến</h3>
        <p className="mt-2 text-muted">Máy chủ chưa phản hồi hoặc đang gián đoạn. Bạn có thể thử tải lại danh sách.</p>
        <div className="mt-4 flex flex-wrap gap-3">
          <a className="action-button" href={destinationHref(query, cursor)}>Thử lại</a>
          {cursor && <a className="text-link self-center" href={destinationHref(query)}>Về trang đầu</a>}
        </div>
      </div>
    );
  }

  return (
    <>
      {page.items.length ? (
        <ul className={grid}>
          {page.items.map((item) => <li key={item.id}><DestinationCard item={item} /></li>)}
        </ul>
      ) : (
        <div className="message-panel">
          <h3 className="text-2xl">Không tìm thấy điểm đến</h3>
          <p className="mt-2 text-muted">{query ? "Hãy thử một tên hoặc địa chỉ khác." : "Danh sách hiện chưa có mục để hiển thị."}</p>
        </div>
      )}
      {(query || cursor || page.nextCursor) && (
        <nav className="mt-6 flex flex-wrap gap-4" aria-label="Phân trang điểm đến">
          {query && <Link className="text-link" href="/destinations" prefetch={false}>Xóa tìm kiếm</Link>}
          {cursor && <Link className="text-link" href={destinationHref(query)} prefetch={false}>Về trang đầu</Link>}
          {page.nextCursor && <Link className="text-link ml-auto" href={destinationHref(query, page.nextCursor)} prefetch={false}>Trang sau</Link>}
        </nav>
      )}
    </>
  );
}

export function DestinationSkeleton() {
  return (
    <div role="status">
      <p className="mb-3 text-sm text-muted">Đang tải điểm đến…</p>
      <div className={grid} aria-hidden="true">
        {[0, 1, 2].map((index) => (
          <Card key={index} className="h-72">
            <div className="h-2/3 bg-placeholder" />
            <CardContent>
              <div className="h-4 w-3/5 rounded bg-placeholder" />
              <div className="mt-3 h-3 w-4/5 rounded bg-placeholder" />
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
