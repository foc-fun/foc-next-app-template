export default function InfoPage() {
  return (
    <div className="container mx-auto max-w-4xl px-4 py-16">
      <div className="space-y-12">
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
            FOC Next App Template
          </h1>
          <p className="text-xl text-muted-foreground">
            Production-ready on-chain Next.js app template for Starknet
          </p>
        </div>

        <div className="prose prose-gray dark:prose-invert max-w-none">
          <section className="space-y-6">
            <div className="rounded-lg border bg-card p-6">
              <h2 className="text-2xl font-semibold mb-4">About This Template</h2>
              <p className="text-muted-foreground mb-4">
                This is a comprehensive starter template for building production-ready decentralized applications on Starknet. 
                It combines modern web development practices with blockchain integration, providing a solid foundation for your next Web3 project.
              </p>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <h3 className="font-semibold">Frontend Stack</h3>
                  <ul className="text-sm text-muted-foreground space-y-1">
                    <li>• Next.js 15.4.6 with App Router</li>
                    <li>• React 19 with TypeScript</li>
                    <li>• Tailwind CSS 4.0</li>
                    <li>• Zustand for state management</li>
                    <li>• Starknet.js for blockchain interaction</li>
                  </ul>
                </div>
                <div className="space-y-2">
                  <h3 className="font-semibold">Blockchain Stack</h3>
                  <ul className="text-sm text-muted-foreground space-y-1">
                    <li>• Starknet Cairo contracts</li>
                    <li>• FOC Engine JS integration</li>
                    <li>• Wallet connection support</li>
                    <li>• Smart contract interaction patterns</li>
                    <li>• Transaction management</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="rounded-lg border bg-card p-6">
              <h2 className="text-2xl font-semibold mb-4">How to Use This Template</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="font-semibold mb-2">1. Clone and Setup</h3>
                  <div className="bg-muted rounded-md p-3 font-mono text-sm">
                    <div>git clone [your-repo]</div>
                    <div>cd frontend && npm install</div>
                    <div>npm run dev</div>
                  </div>
                </div>
                <div>
                  <h3 className="font-semibold mb-2">2. Customize the Template</h3>
                  <p className="text-sm text-muted-foreground">
                    • Update the app name in Header.tsx and metadata<br/>
                    • Modify the color scheme in globals.css<br/>
                    • Add your own pages and components<br/>
                    • Integrate your smart contracts<br/>
                    • Configure wallet connection providers
                  </p>
                </div>
                <div>
                  <h3 className="font-semibold mb-2">3. Deploy Your Contracts</h3>
                  <div className="bg-muted rounded-md p-3 font-mono text-sm">
                    <div>cd onchain</div>
                    <div>scarb build</div>
                    <div>scarb test</div>
                  </div>
                </div>
              </div>
            </div>

            <div className="rounded-lg border bg-card p-6">
              <h2 className="text-2xl font-semibold mb-4">Example App: Counter</h2>
              <p className="text-muted-foreground mb-4">
                This template includes a fully functional counter application demonstrating key concepts:
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>
                  <strong>State Management:</strong> Uses Zustand for persistent client-side state with localStorage
                </li>
                <li>
                  <strong>Navigation:</strong> Multi-page app with client-side routing using Next.js App Router
                </li>
                <li>
                  <strong>Interactive UI:</strong> Counter with increment/decrement functionality
                </li>
                <li>
                  <strong>Points System:</strong> Earn points and spend them on upgrades
                </li>
                <li>
                  <strong>Shop Mechanics:</strong> Purchase power-ups that modify counter behavior
                </li>
                <li>
                  <strong>Responsive Design:</strong> Mobile-first approach with Tailwind CSS
                </li>
              </ul>
            </div>

            <div className="rounded-lg border bg-card p-6">
              <h2 className="text-2xl font-semibold mb-4">Key Features</h2>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-3">
                  <div>
                    <h3 className="font-semibold text-sm">🚀 Production Ready</h3>
                    <p className="text-xs text-muted-foreground">TypeScript, ESLint, and modern tooling configured</p>
                  </div>
                  <div>
                    <h3 className="font-semibold text-sm">🎨 Modern UI</h3>
                    <p className="text-xs text-muted-foreground">Beautiful, accessible components with Tailwind CSS</p>
                  </div>
                  <div>
                    <h3 className="font-semibold text-sm">⚡ Fast Development</h3>
                    <p className="text-xs text-muted-foreground">Turbopack for lightning-fast HMR</p>
                  </div>
                </div>
                <div className="space-y-3">
                  <div>
                    <h3 className="font-semibold text-sm">🔗 Web3 Integration</h3>
                    <p className="text-xs text-muted-foreground">Starknet.js and FOC Engine ready to use</p>
                  </div>
                  <div>
                    <h3 className="font-semibold text-sm">📦 State Management</h3>
                    <p className="text-xs text-muted-foreground">Zustand for simple, powerful state handling</p>
                  </div>
                  <div>
                    <h3 className="font-semibold text-sm">🎯 Best Practices</h3>
                    <p className="text-xs text-muted-foreground">Clean architecture and maintainable code structure</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="rounded-lg border bg-card p-6">
              <h2 className="text-2xl font-semibold mb-4">Next Steps</h2>
              <p className="text-muted-foreground mb-4">
                Ready to build your own dApp? Here are some suggestions:
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Replace the counter logic with your application logic</li>
                <li>• Implement wallet connection using the Login button</li>
                <li>• Create smart contracts for on-chain functionality</li>
                <li>• Add API routes for backend operations</li>
                <li>• Integrate analytics and monitoring</li>
                <li>• Set up CI/CD pipelines for deployment</li>
                <li>• Add comprehensive testing suites</li>
              </ul>
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}