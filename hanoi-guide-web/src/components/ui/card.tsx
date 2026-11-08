import type { ComponentProps } from "react";
import { cn } from "@/lib/utils";

export function Card({ className, ...props }: ComponentProps<"article">) {
  return <article data-slot="card" className={cn("overflow-hidden rounded-2xl border border-line bg-surface", className)} {...props} />;
}

export function CardContent({ className, ...props }: ComponentProps<"div">) {
  return <div data-slot="card-content" className={cn("p-5 sm:p-6", className)} {...props} />;
}
