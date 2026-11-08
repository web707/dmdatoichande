const packagedImages = new Map([
  ["https://upload.wikimedia.org/wikipedia/commons/7/79/Thap_Rua.jpg", "/images/hoan-kiem.webp"],
  ["https://upload.wikimedia.org/wikipedia/commons/3/39/Hanoi_Temple_of_Literature_%28cropped%29.jpg", "/images/van-mieu.webp"],
]);

function imageSource(value: string) {
  const packaged = packagedImages.get(value);
  if (packaged) return packaged;
  const url = URL.parse(value);
  return url?.protocol === "https:" && !url.username && !url.password ? url.href : undefined;
}

export function DestinationPhoto({ url, credit }: { url: string; credit: string }) {
  const image = imageSource(url);

  return (
    <figure>
      <div className="relative grid aspect-[16/10] place-items-center overflow-hidden bg-placeholder">
        <svg aria-hidden="true" className="size-9 text-muted" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.25" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="4" width="18" height="16" rx="2" />
          <path d="m3 16 5-4 4 4 4-6 5 6M8 8h.01" />
        </svg>
        {image && (
          <picture className="absolute inset-0">
            {image === "/images/hoan-kiem.webp" && <source media="(width < 40rem)" srcSet="/images/hoan-kiem-small.webp" />}
            {/* Catalog images from custom hosts load directly in the browser. */}
            <img className="h-full w-full object-cover" src={image} alt="" loading="lazy" decoding="async" referrerPolicy="no-referrer" />
          </picture>
        )}
      </div>
      {image && credit && <figcaption className="px-5 pt-2 wrap-anywhere text-xs leading-relaxed text-muted sm:px-6">{credit}</figcaption>}
    </figure>
  );
}
