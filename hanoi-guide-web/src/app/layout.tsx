import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";
import "@/styles/globals.css";

export const metadata: Metadata = {
  title: { default: "Hanoi Guide", template: "%s · Hanoi Guide" },
  description: "Cẩm nang khám phá địa danh, di sản và văn hóa Hà Nội.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="vi">
      <body>
        <a className="skip-link" href="#main">Đến nội dung chính</a>
        <header className="border-b border-line bg-surface">
          <div className="site-width flex min-h-16 items-center justify-between gap-4 py-3">
            <Link className="brand" href="/destinations" prefetch={false}>
              <span className="brand-mark" aria-hidden="true">H</span>
              <span lang="en">Hanoi Guide</span>
            </Link>
            <nav aria-label="Điều hướng chính">
              <Link className="nav-link" href="/destinations" prefetch={false}>Điểm đến</Link>
            </nav>
          </div>
        </header>
        <main className="site-width flex-1 py-6 sm:py-10" id="main" tabIndex={-1}>{children}</main>
        <footer className="border-t border-line py-6 text-sm text-muted">
          <div className="site-width flex flex-wrap items-center justify-between gap-x-6 gap-y-2">
            <span lang="en" className="font-semibold text-ink">Hanoi Guide</span>
            <span>Hà Nội, Việt Nam</span>
          </div>
        </footer>
      </body>
    </html>
  );
}
