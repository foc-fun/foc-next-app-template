# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Production-ready on-chain Next.js app template for rapid development of fully-featured Starknet applications. The frontend includes comprehensive boilerplate and modules for quick deployment, while the onchain directory contains Cairo contract templates. Frontend-Starknet interactions are handled through foc-engine-js package and starknet-js.

## Commands

### Frontend Development
```bash
cd frontend
npm run dev    # Start development server with Turbopack (http://localhost:3000)
npm run build  # Build for production
npm run start  # Start production server
npm run lint   # Run ESLint
```

### Smart Contract Development
```bash
cd onchain
scarb test     # Run Cairo contract tests
scarb build    # Build Cairo contracts
```

## Architecture

### Frontend (`/frontend`)
- **Next.js 15.4.6** with App Router (`/src/app/`)
- **React 19.1.0** with TypeScript 5
- **Tailwind CSS 4** using inline `@theme` configuration (no tailwind.config.js)
- **Turbopack** enabled for faster development builds
- **Path aliasing**: `@/*` maps to `./src/*`
- **Geist fonts** (Sans and Mono) configured in layout

### Onchain (`/onchain`)
- **Cairo** smart contracts for Starknet
- **Scarb 2.11.1** package manager
- **Starknet Foundry 0.42.0** for testing
- Contract interfaces defined in `src/lib.cairo`

## Key Conventions

### Frontend Structure
- App Router pages in `/frontend/src/app/`
- Global styles with CSS custom properties in `globals.css`
- Components should use Tailwind CSS utility classes
- TypeScript strict mode enabled

### Smart Contract Structure
- Main contract logic in `/onchain/src/lib.cairo`
- Tests in `/onchain/tests/`
- Use Scarb for dependency management

## Important Notes

- No frontend testing framework currently configured
- ESLint 9 with flat config format
- React 19 is cutting-edge - watch for stability issues
- Tailwind CSS 4 has different API than v3 (uses CSS-in-JS approach)