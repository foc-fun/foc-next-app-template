'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'

export default function Header() {
  const pathname = usePathname()

  const handleLogin = () => {
    console.log('Login clicked - integrate wallet connection here')
  }

  const isActive = (path: string) => pathname === path

  return (
    <header className="sticky top-0 z-50 w-full border-b border-border/40 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between px-4 mx-auto max-w-7xl">
        <Link 
          href="/" 
          className="flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-lg">F</span>
          </div>
          <span className="font-semibold text-lg">My App Name</span>
        </Link>

        <nav className="flex items-center gap-6">
          <Link 
            href="/shop"
            className={`text-sm font-medium transition-colors hover:text-primary ${
              isActive('/shop') 
                ? 'text-foreground' 
                : 'text-muted-foreground'
            }`}
          >
            Shop
          </Link>
          <Link 
            href="/info"
            className={`text-sm font-medium transition-colors hover:text-primary ${
              isActive('/info') 
                ? 'text-foreground' 
                : 'text-muted-foreground'
            }`}
          >
            Info
          </Link>
          <Link 
            href="/foc-demo"
            className={`text-sm font-medium transition-colors hover:text-primary ${
              isActive('/foc-demo') 
                ? 'text-foreground' 
                : 'text-muted-foreground'
            }`}
          >
            FOC Demo
          </Link>
          <button
            onClick={handleLogin}
            className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none ring-offset-background bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2"
          >
            Login
          </button>
        </nav>
      </div>
    </header>
  )
}