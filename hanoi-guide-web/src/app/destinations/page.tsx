import type { Metadata } from "next";
import { Suspense } from "react";
import { DestinationResults, DestinationSkeleton, destinationHref } from "@/features/destinations/destination-results";

export const metadata: Metadata = {
  title: "Khám phá Hà Nội",
  description: "Tìm điểm đến tại Hà Nội theo tên hoặc địa chỉ và khám phá câu chuyện của từng địa danh.",
};

type SearchParams = Record<string, string | string[] | undefined>;

export default async function DestinationsPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  const params = await searchParams;
  const query = typeof params.q === "string" ? params.q.trim().slice(0, 100) : "";
  const cursor = typeof params.cursor === "string" ? params.cursor : "";

  return (
    <>
      <section className="hero" aria-labelledby="page-title">
        <div className="relative z-10 max-w-xl">
          <p className="eyebrow mb-4 text-warm-light">Cẩm nang du lịch</p>
          <h1 id="page-title" className="text-[clamp(2.6rem,8vw,5.75rem)] leading-[0.98] tracking-tight">Khám phá Hà Nội</h1>
          <p className="mt-5 max-w-sm text-base leading-relaxed text-hero-text sm:text-lg">Tìm những địa danh, di sản và góc phố kể câu chuyện của Thủ đô.</p>
        </div>
        <a className="hero-credit" href="https://commons.wikimedia.org/wiki/File:Thap_Rua.jpg">Tháp Rùa · Cyril Doussin · CC BY-SA 2.0</a>
      </section>

      <section className="mt-10 sm:mt-14" aria-labelledby="list-title">
        <div className="mb-6 grid items-end gap-5 md:grid-cols-[1fr_minmax(0,27rem)]">
          <div>
            <h2 id="list-title" className="text-3xl tracking-tight sm:text-4xl">Điểm đến</h2>
            <p className="mt-2 text-sm leading-relaxed text-muted">Tìm theo tên tiếng Việt, tên tiếng Anh hoặc địa chỉ.</p>
          </div>
          <form action="/destinations" method="get" role="search" className="flex gap-2">
            <label className="sr-only" htmlFor="destination-query">Tìm điểm đến</label>
            <input id="destination-query" className="search-input" name="q" type="search" placeholder="Ví dụ: Hồ Hoàn Kiếm" defaultValue={query} maxLength={100} />
            <button className="action-button" type="submit">Tìm kiếm</button>
          </form>
        </div>

        <Suspense key={destinationHref(query, cursor)} fallback={<DestinationSkeleton />}>
          <DestinationResults query={query} cursor={cursor} />
        </Suspense>
      </section>
    </>
  );
}
