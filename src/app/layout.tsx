import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "NEXTLIB | Computer Science Library",
  description: "Computer Science library catalogue and circulation management."
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
