'use client'

import { useCounterStore, upgrades } from '@/lib/store/counter-store'
import { useState } from 'react'
import Link from 'next/link'

export default function ShopPage() {
  const { points, purchases, buyUpgrade } = useCounterStore()
  const [purchaseMessage, setPurchaseMessage] = useState<string>('')

  const handlePurchase = (upgrade: typeof upgrades[0]) => {
    if (purchases.includes(upgrade.id)) {
      setPurchaseMessage('Already purchased!')
      setTimeout(() => setPurchaseMessage(''), 2000)
      return
    }

    if (points < upgrade.cost) {
      setPurchaseMessage('Not enough points!')
      setTimeout(() => setPurchaseMessage(''), 2000)
      return
    }

    const success = buyUpgrade(upgrade)
    if (success) {
      setPurchaseMessage('Purchase successful!')
      setTimeout(() => setPurchaseMessage(''), 2000)
    }
  }

  return (
    <div className="container mx-auto max-w-6xl px-4 py-16">
      <div className="space-y-8">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            Upgrade Shop
          </h1>
          <p className="text-muted-foreground text-lg">
            Spend your points to increase your counter power!
          </p>
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary">
            <span className="text-2xl font-bold">{points}</span>
            <span className="text-sm">Points Available</span>
          </div>
        </div>

        {purchaseMessage && (
          <div className="flex justify-center">
            <div className={`px-4 py-2 rounded-lg text-sm font-medium ${
              purchaseMessage.includes('successful') 
                ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400'
                : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
            }`}>
              {purchaseMessage}
            </div>
          </div>
        )}

        <div className="grid gap-6 md:grid-cols-2">
          {upgrades.map((upgrade) => {
            const isPurchased = purchases.includes(upgrade.id)
            const canAfford = points >= upgrade.cost
            
            return (
              <div
                key={upgrade.id}
                className={`relative rounded-xl border p-6 transition-all ${
                  isPurchased 
                    ? 'bg-primary/5 border-primary/50' 
                    : 'bg-card hover:shadow-lg'
                }`}
              >
                {isPurchased && (
                  <div className="absolute top-4 right-4">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary text-primary-foreground">
                      Owned
                    </span>
                  </div>
                )}
                
                <div className="space-y-4">
                  <div>
                    <h3 className="text-xl font-semibold">{upgrade.name}</h3>
                    <p className="text-sm text-muted-foreground mt-1">
                      {upgrade.description}
                    </p>
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="space-y-1">
                      <div className="text-2xl font-bold">±{upgrade.incrementValue}</div>
                      <div className="text-xs text-muted-foreground">Power Level</div>
                    </div>
                    <div className="text-right space-y-1">
                      <div className="text-2xl font-bold">{upgrade.cost}</div>
                      <div className="text-xs text-muted-foreground">Points</div>
                    </div>
                  </div>

                  <button
                    onClick={() => handlePurchase(upgrade)}
                    disabled={isPurchased || !canAfford}
                    className={`w-full inline-flex items-center justify-center rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background h-10 px-4 py-2 ${
                      isPurchased 
                        ? 'bg-secondary text-secondary-foreground cursor-not-allowed'
                        : canAfford
                        ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                        : 'bg-secondary text-secondary-foreground cursor-not-allowed'
                    }`}
                  >
                    {isPurchased ? 'Already Owned' : canAfford ? 'Purchase' : 'Not Enough Points'}
                  </button>
                </div>
              </div>
            )
          })}
        </div>

        <div className="text-center text-sm text-muted-foreground">
          <p>
            Upgrades are permanent and stack with each other. Go back to the{' '}
            <Link href="/" className="text-primary hover:underline">
              Counter
            </Link>{' '}
            to earn more points!
          </p>
        </div>
      </div>
    </div>
  )
}