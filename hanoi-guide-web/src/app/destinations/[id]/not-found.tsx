import Link from "next/link";

export default function DestinationNotFound() {
  return (
    <div className="message-panel">
      <h1 className="text-3xl">Không tìm thấy điểm đến</h1>
      <p className="mt-2 text-muted">Điểm đến có thể đã được gỡ khỏi danh sách.</p>
      <Link className="text-link mt-4" href="/destinations" prefetch={false}>Về danh sách điểm đến</Link>
    </div>
  );
}
