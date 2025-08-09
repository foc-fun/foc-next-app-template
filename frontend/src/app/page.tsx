'use client'

import { useCounterStore } from '@/lib/store/counter-store'
import Link from 'next/link'

export default function HomePage() {
  const { count, points, incrementValue, increment, decrement } = useCounterStore()

  return (
    <div className="container mx-auto max-w-4xl px-4 py-16">
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-8">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
            Counter App
          </h1>
          <p className="text-muted-foreground text-lg">
            Click the buttons to change the counter value and earn points!
          </p>
        </div>

        <div className="flex flex-col items-center gap-6 p-8 rounded-2xl border bg-card">
          <div className="text-center space-y-2">
            <div className="text-6xl font-bold tabular-nums">
              {count}
            </div>
            <div className="text-sm text-muted-foreground">
              Current Count
            </div>
          </div>

          <div className="flex gap-4">
            <button
              onClick={decrement}
              className="inline-flex items-center justify-center rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background bg-secondary text-secondary-foreground hover:bg-secondary/80 h-12 px-6 py-3 text-lg"
            >
              -{incrementValue}
            </button>
            <button
              onClick={increment}
              className="inline-flex items-center justify-center rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background bg-primary text-primary-foreground hover:bg-primary/90 h-12 px-6 py-3 text-lg"
            >
              +{incrementValue}
            </button>
          </div>

          <div className="flex items-center gap-6 pt-4 border-t w-full">
            <div className="flex-1 text-center">
              <div className="text-2xl font-semibold">{points}</div>
              <div className="text-xs text-muted-foreground">Points Available</div>
            </div>
            <div className="flex-1 text-center">
              <div className="text-2xl font-semibold">±{incrementValue}</div>
              <div className="text-xs text-muted-foreground">Current Power</div>
            </div>
          </div>
        </div>

        <div className="text-center text-sm text-muted-foreground max-w-md">
          <p>
            Earn points by incrementing the counter. Use your points in the{' '}
            <Link href="/shop" className="text-primary hover:underline">
              Shop
            </Link>{' '}
            to buy power upgrades!
          </p>
        </div>
      </div>
    </div>
  )
}