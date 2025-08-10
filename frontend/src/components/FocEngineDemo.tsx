"use client";

import { useState } from "react";
import { 
  useFocEngine, 
  useStarknet
} from "@foc-engine/react";

export default function FocEngineDemo() {
  const [txHash, setTxHash] = useState<string>("");
  const [notifications, setNotifications] = useState<any[]>([]);
  const [exitingNotifications, setExitingNotifications] = useState<Set<string>>(new Set());
  
  // FOC Engine hooks
  const { 
    engine, 
    paymaster, 
    isConnected: isFocConnected,
    network,
    connect: connectFoc,
    disconnect: disconnectFoc,
    buildGaslessTx,
    sendGaslessTx
  } = useFocEngine();

  // Starknet hooks
  const {
    account,
    provider,
    isConnected: isStarknetConnected,
    accountInfo,
    chainId,
    connect: connectStarknet,
    disconnect: disconnectStarknet,
    getBalance,
    getAllBalances
  } = useStarknet();

  // Simple notification helper with animations - adds to beginning of array (most recent first)
  const addNotification = (notification: any) => {
    const newNotification = { ...notification, id: Date.now().toString(), isNew: true };
    setNotifications(prev => [newNotification, ...prev]);
    
    // Remove the "new" flag after animation completes
    setTimeout(() => {
      setNotifications(prev => prev.map(n => 
        n.id === newNotification.id ? { ...n, isNew: false } : n
      ));
    }, 100);
    
    // Start exit animation before removal
    setTimeout(() => {
      setExitingNotifications(prev => new Set(prev).add(newNotification.id));
      
      // Actually remove after exit animation
      setTimeout(() => {
        setNotifications(prev => prev.filter(n => n.id !== newNotification.id));
        setExitingNotifications(prev => {
          const newSet = new Set(prev);
          newSet.delete(newNotification.id);
          return newSet;
        });
      }, 300); // Exit animation duration
    }, notification.duration || 3000);
  };

  const handleConnectWallet = async () => {
    try {
      // Connect to Starknet wallet
      await connectStarknet();
      
      // Initialize FOC Engine
      connectFoc({ network: "SN_SEPOLIA" });

      // Show notification
      addNotification({
        type: "success",
        title: "Wallet Connected",
        message: `Connected to ${network}`,
        duration: 3000
      });
    } catch (error) {
      console.error("Connection failed:", error);
      addNotification({
        id: Date.now().toString(),
        type: "error",
        title: "Connection Failed",
        message: "Failed to connect wallet",
        duration: 5000
      });
    }
  };

  const handleDisconnect = () => {
    disconnectStarknet();
    disconnectFoc();
    
    addNotification({
      type: "info",
      title: "Wallet Disconnected",
      message: "You have been disconnected",
      duration: 3000
    });
  };

  const handleGaslessTransaction = async () => {
    if (!account || !paymaster) {
      addNotification({
        type: "warning",
        title: "Not Connected",
        message: "Please connect your wallet first",
        duration: 3000
      });
      return;
    }

    // Show info about demo limitations
    addNotification({
      type: "info", 
      title: "Demo Mode",
      message: "This is a demo - FOC Engine paymaster API endpoints may not be available",
      duration: 4000
    });

    try {
      // Example: Build a gasless transaction
      const calls = [
        {
          contractAddress: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", // ETH contract
          entrypoint: "transfer", 
          calldata: [accountInfo?.address || "0x0", "1000000000000000"] // 0.001 ETH
        }
      ];

      addNotification({
        type: "info",
        title: "Building Transaction",
        message: "Attempting to build gasless transaction...",
        duration: 2000
      });

      const gaslessTx = await buildGaslessTx({ calls });
      
      // Execute transaction (gasless transactions are handled by paymaster internally)
      const result = await sendGaslessTx(gaslessTx);
      
      setTxHash(result.transaction_hash || result);
      
      addNotification({
        type: "success",
        title: "Transaction Sent",
        message: `Gasless tx sent: ${result.transaction_hash || result}`,
        duration: 5000
      });

    } catch (error) {
      console.error("Transaction failed:", error);
      
      // Check if it's a network/API error
      if (error instanceof TypeError && error.message.includes("fetch")) {
        addNotification({
          type: "error",
          title: "API Connection Failed",
          message: "FOC Engine paymaster API is not accessible. This is expected in demo mode.",
          duration: 6000
        });
      } else if (error instanceof Error && error.message.includes("Failed to build")) {
        addNotification({
          type: "error", 
          title: "Paymaster Service Unavailable",
          message: "The paymaster service is not available. Check if the FOC Engine API is running.",
          duration: 6000
        });
      } else {
        addNotification({
          type: "error",
          title: "Transaction Failed",
          message: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
          duration: 5000
        });
      }
    }
  };

  const fetchBalances = async () => {
    if (!accountInfo?.address) return;

    try {
      const balances = await getAllBalances(accountInfo.address);
      console.log("Balances:", balances);
      
      addNotification({
        type: "info",
        title: "Balances Fetched",
        message: `ETH: ${balances.ETH || "0"}, STRK: ${balances.STRK || "0"}`,
        duration: 5000
      });
    } catch (error) {
      console.error("Failed to fetch balances:", error);
    }
  };

  return (
    <div className="p-8 space-y-6">
      <div className="bg-white/5 rounded-lg p-6 backdrop-blur">
        <h2 className="text-2xl font-bold mb-4">FOC Engine Integration Demo</h2>
        
        {/* Connection Status */}
        <div className="mb-6 space-y-2">
          <div className="flex items-center gap-2">
            <span className={`w-3 h-3 rounded-full ${isStarknetConnected ? "bg-green-500" : "bg-red-500"}`} />
            <span>Starknet: {isStarknetConnected ? "Connected" : "Disconnected"}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className={`w-3 h-3 rounded-full ${isFocConnected ? "bg-green-500" : "bg-red-500"}`} />
            <span>FOC Engine: {isFocConnected ? "Connected" : "Disconnected"}</span>
          </div>
          {accountInfo && (
            <div className="text-sm text-gray-400">
              Address: {accountInfo.address.slice(0, 6)}...{accountInfo.address.slice(-4)}
            </div>
          )}
        </div>

        {/* Actions */}
        <div className="flex gap-4 mb-6">
          {!isStarknetConnected ? (
            <button
              onClick={handleConnectWallet}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors"
            >
              Connect Wallet
            </button>
          ) : (
            <>
              <button
                onClick={handleDisconnect}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
              >
                Disconnect
              </button>
              <button
                onClick={fetchBalances}
                className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg transition-colors"
              >
                Fetch Balances
              </button>
              <button
                onClick={handleGaslessTransaction}
                className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg transition-colors disabled:bg-gray-500 disabled:cursor-not-allowed"
                disabled={!isFocConnected}
                title={!isFocConnected ? "Connect FOC Engine first" : "Attempt to send gasless transaction (demo mode)"}
              >
                Send Gasless Tx
              </button>
            </>
          )}
        </div>

        {/* Network Info */}
        <div className="mb-6">
          <h3 className="font-semibold mb-2">Network Info</h3>
          <div className="text-sm space-y-1">
            <div>FOC Network: {network}</div>
            <div>Chain ID: {chainId}</div>
            <div className="text-xs text-gray-400 mt-2">
              💡 Gasless transactions require FOC Engine paymaster API access
            </div>
          </div>
        </div>

        {/* Transaction Hash */}
        {txHash && (
          <div className="mt-4 p-3 bg-green-500/10 rounded border border-green-500/20">
            <div className="text-sm">
              <span className="font-semibold">Last Transaction:</span>
              <div className="font-mono text-xs mt-1">{txHash}</div>
            </div>
          </div>
        )}

        {/* Notifications - newest first */}
        {notifications.length > 0 && (
          <div className="mt-4">
            <h3 className="font-semibold mb-2">Notifications</h3>
            <div className="flex flex-col gap-2">
              {notifications.map((notif: any) => {
                const isExiting = exitingNotifications.has(notif.id);
                const isNew = notif.isNew;
                
                return (
                  <div
                    key={notif.id}
                    className={`p-3 rounded-lg text-sm transition-all duration-300 transform ${
                      isNew 
                        ? "opacity-0 -translate-y-4 scale-95" 
                        : isExiting 
                          ? "opacity-0 translate-x-full scale-95" 
                          : "opacity-100 translate-y-0 translate-x-0 scale-100"
                    } ${
                      notif.type === "success" ? "bg-green-500/10 border border-green-500/20" :
                      notif.type === "error" ? "bg-red-500/10 border border-red-500/20" :
                      notif.type === "warning" ? "bg-yellow-500/10 border border-yellow-500/20" :
                      "bg-blue-500/10 border border-blue-500/20"
                    }`}
                    style={{
                      animation: isNew ? "slideInFromTop 0.3s ease-out forwards" : undefined
                    }}
                  >
                    <div className="font-semibold">{notif.title}</div>
                    <div className="text-xs opacity-80">{notif.message}</div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}