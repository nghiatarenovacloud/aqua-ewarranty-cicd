import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'AQUA E-WARRANTY Frontend',
  description: 'Multi-Service Frontend Application',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}