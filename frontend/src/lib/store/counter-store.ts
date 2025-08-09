import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface Upgrade {
  id: string
  name: string
  description: string
  cost: number
  incrementValue: number
}

interface CounterState {
  count: number
  points: number
  incrementValue: number
  decrementValue: number
  purchases: string[]
  increment: () => void
  decrement: () => void
  buyUpgrade: (upgrade: Upgrade) => boolean
  reset: () => void
}

export const upgrades: Upgrade[] = [
  {
    id: 'upgrade-1',
    name: 'Double Power',
    description: 'Increase increment/decrement to ±2',
    cost: 10,
    incrementValue: 2,
  },
  {
    id: 'upgrade-2',
    name: 'Triple Power',
    description: 'Increase increment/decrement to ±3',
    cost: 25,
    incrementValue: 3,
  },
  {
    id: 'upgrade-3',
    name: 'Quad Power',
    description: 'Increase increment/decrement to ±4',
    cost: 50,
    incrementValue: 4,
  },
  {
    id: 'upgrade-4',
    name: 'Mega Power',
    description: 'Increase increment/decrement to ±5',
    cost: 100,
    incrementValue: 5,
  },
]

export const useCounterStore = create<CounterState>()(
  persist(
    (set) => ({
      count: 0,
      points: 0,
      incrementValue: 1,
      decrementValue: 1,
      purchases: [],
      increment: () => set((state) => ({ 
        count: state.count + state.incrementValue,
        points: state.points + state.incrementValue
      })),
      decrement: () => set((state) => ({ 
        count: state.count - state.decrementValue 
      })),
      buyUpgrade: (upgrade: Upgrade) => {
        let purchased = false
        set((state) => {
          if (state.points >= upgrade.cost && !state.purchases.includes(upgrade.id)) {
            purchased = true
            return {
              points: state.points - upgrade.cost,
              incrementValue: upgrade.incrementValue,
              decrementValue: upgrade.incrementValue,
              purchases: [...state.purchases, upgrade.id]
            }
          }
          return state
        })
        return purchased
      },
      reset: () => set({ 
        count: 0, 
        points: 0, 
        incrementValue: 1, 
        decrementValue: 1,
        purchases: [] 
      }),
    }),
    {
      name: 'counter-storage',
    }
  )
)