# Counter Game Smart Contracts

A fully on-chain counter game built with Cairo for Starknet, featuring dynamic upgrade management and comprehensive administrative controls.

## Features

### Core Game Mechanics
- **Increment/Decrement Counter**: Basic gameplay actions
- **Point System**: Earn points by incrementing (not decrementing)
- **Upgrade System**: Purchase power upgrades to increase increment/decrement values
- **Player State Management**: Per-address game state tracking

### Administrative Controls
- **Owner-Only Access**: Secure administrative functions
- **Dynamic Upgrade Management**: Add, modify, or remove upgrades
- **Ownership Transfer**: Transfer contract ownership
- **Event Emissions**: Full transparency through events

## Quick Start

### Prerequisites
- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Testing and deployment tools
- [jq](https://stedolan.github.io/jq/) - JSON processor (for setup scripts)

### Build & Test
```bash
# Build contracts
scarb build

# Run tests
scarb test
# or
snforge test
```

### Deploy Contract
```bash
# Deploy to devnet (example)
starknet deploy --contract target/dev/onchain_CounterGame.sierra.json \
  --constructor-calldata <OWNER_ADDRESS>
```

## Configuration Management

### Upgrade Configuration

The contract supports dynamic upgrade configuration through JSON files and setup scripts.

#### 1. Configure Upgrades (upgrades.json)
```json
{
  "upgrades": [
    {
      "id": 1,
      "name": "Double Power",
      "description": "Increase increment/decrement to ±2",
      "cost": 10,
      "increment_value": 2
    },
    {
      "id": 2,
      "name": "Triple Power", 
      "description": "Increase increment/decrement to ±3",
      "cost": 25,
      "increment_value": 3
    }
  ]
}
```

#### 2. Run Setup Script
```bash
# Setup upgrades from JSON config
CONTRACT_ADDRESS=0x... ./scripts/setup-upgrades.sh

# With custom network settings
NETWORK=sepolia \
RPC_URL=https://starknet-sepolia.public.blastapi.io/rpc/v0_7 \
ACCOUNT=my-account \
CONTRACT_ADDRESS=0x... \
./scripts/setup-upgrades.sh
```

#### Script Features
- ✅ **JSON Validation**: Validates configuration file format
- ✅ **Dependency Checking**: Ensures required tools are installed
- ✅ **Smart Updates**: Updates existing upgrades or adds new ones
- ✅ **Network Support**: Configurable for devnet, testnet, mainnet
- ✅ **Error Handling**: Comprehensive error reporting and recovery
- ✅ **Status Display**: Shows current and final configurations

#### Environment Variables
- `CONTRACT_ADDRESS` (required): Deployed contract address
- `NETWORK` (optional): Target network (default: devnet)
- `RPC_URL` (optional): RPC endpoint (default: http://localhost:5050) 
- `ACCOUNT` (optional): Sncast account (default: devnet)

## Contract Interface

### Core Game Functions
```cairo
// Game actions
fn increment(ref self: TContractState);
fn decrement(ref self: TContractState);
fn reset(ref self: TContractState);
fn buy_upgrade(ref self: TContractState, upgrade_id: u32) -> bool;

// View functions
fn get_player_state(self: @TContractState, user: ContractAddress) -> PlayerState;
fn get_current_count(self: @TContractState, user: ContractAddress) -> u32;
fn get_current_points(self: @TContractState, user: ContractAddress) -> u32;
```

### Administrative Functions (Owner Only)
```cairo
// Upgrade management
fn set_upgrade_config(ref self: TContractState, upgrade_id: u32, cost: u32, increment_value: u32);
fn add_new_upgrade(ref self: TContractState, upgrade_id: u32, cost: u32, increment_value: u32);
fn remove_upgrade(ref self: TContractState, upgrade_id: u32);

// Ownership
fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
fn get_owner(self: @TContractState) -> ContractAddress;
```

## Game Mechanics

### Initial State
- Count: 0
- Points: 0 
- Increment/Decrement Value: 1

### Gameplay Loop
1. **Increment**: Increases count and awards points equal to increment value
2. **Decrement**: Decreases count (no points awarded)  
3. **Purchase Upgrades**: Spend points to increase increment/decrement power
4. **Higher Power**: More efficient point generation

### Default Upgrades
| ID | Name | Cost | Power | Description |
|----|------|------|-------|-------------|
| 1 | Double Power | 10 | 2x | Increase to ±2 |
| 2 | Triple Power | 25 | 3x | Increase to ±3 |
| 3 | Quad Power | 50 | 4x | Increase to ±4 |
| 4 | Mega Power | 100 | 5x | Increase to ±5 |

## Events

### Game Events
- `CounterIncremented`: Emitted on increment actions
- `CounterDecremented`: Emitted on decrement actions  
- `UpgradePurchased`: Emitted on upgrade purchases
- `PlayerReset`: Emitted on player state reset

### Administrative Events
- `UpgradeConfigChanged`: Emitted on upgrade modifications
- `OwnershipTransferred`: Emitted on ownership changes

## Testing

The project includes comprehensive test coverage with 35 tests:

### Game Logic Tests (18 tests)
- Core game actions and mechanics
- Upgrade system functionality
- Player state management
- Edge cases and validations
- Event emissions

### Owner Functionality Tests (17 tests)  
- Access control validation
- Upgrade configuration management
- Ownership transfer functionality
- Administrative event emissions

```bash
# Run all tests
snforge test

# Run specific test file
snforge test --exact test_counter_game
snforge test --exact test_owner_functions
```

## Development

### Project Structure
```
onchain/
├── src/
│   ├── lib.cairo           # Main library exports
│   └── counter.cairo       # Counter game contract
├── tests/
│   ├── test_counter_game.cairo    # Core game tests
│   └── test_owner_functions.cairo # Admin tests
├── scripts/
│   └── setup-upgrades.sh  # Configuration script
├── upgrades.json          # Upgrade configuration
├── Scarb.toml            # Project configuration
└── snfoundry.toml        # Foundry configuration
```

### Adding New Features
1. Implement feature in `src/counter.cairo`
2. Add corresponding tests in `tests/`
3. Update configuration files if needed
4. Run full test suite: `snforge test`

## Security Considerations

- **Owner-Only Functions**: Critical administrative functions are protected by `_assert_only_owner()`
- **Input Validation**: All functions validate inputs and check preconditions
- **Event Transparency**: All state changes emit events for auditability
- **Reentrancy Safe**: No external calls in state-changing functions

## License

This project is part of the FOC (Fully On Chain) ecosystem.