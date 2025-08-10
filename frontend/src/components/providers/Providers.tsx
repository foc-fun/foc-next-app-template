"use client";

import React, { ReactNode } from "react";
import { FocEngineProvider, StarknetProvider } from "@foc-engine/react";

interface ProvidersProps {
  children: ReactNode;
}

export default function Providers({ children }: ProvidersProps) {
  return (
    <StarknetProvider
      defaultRpcUrl="https://starknet-sepolia.public.blastapi.io"
      defaultChainId="SN_SEPOLIA"
    >
      <FocEngineProvider defaultNetwork="SN_SEPOLIA">
        {children as any}
      </FocEngineProvider>
    </StarknetProvider>
  );
}