use starknet::ContractAddress;
use super::types::{PlayerState, UpgradeConfig};

#[starknet::interface]
pub trait ICounterStore<TContractState> {
    // Player state management
    fn get_player_state(self: @TContractState, user: ContractAddress) -> PlayerState;
    fn set_player_state(ref self: TContractState, user: ContractAddress, state: PlayerState);
    
    // Purchase tracking
    fn has_purchased_upgrade(self: @TContractState, user: ContractAddress, upgrade_id: u32) -> bool;
    fn add_purchase(ref self: TContractState, user: ContractAddress, upgrade_id: u32);
    fn get_user_purchases(self: @TContractState, user: ContractAddress) -> Array<u32>;
    
    // Upgrade configurations
    fn get_upgrade_config(self: @TContractState, upgrade_id: u32) -> UpgradeConfig;
    fn set_upgrade_config(ref self: TContractState, upgrade_id: u32, config: UpgradeConfig);
    
    // Admin functions
    fn initialize_upgrades(ref self: TContractState);
    fn reset_player(ref self: TContractState, user: ContractAddress);
}

#[starknet::component]
pub mod CounterStoreComponent {
    use starknet::ContractAddress;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
        Map, Vec, MutableVecTrait
    };
    use super::{ICounterStore, PlayerState, UpgradeConfig};

    #[storage]
    struct Storage {
        player_states: Map<ContractAddress, PlayerState>,
        user_purchases: Map<ContractAddress, Vec<u32>>,
        upgrade_configs: Map<u32, UpgradeConfig>,
        initialized: bool,
    }

    #[embeddable_as(CounterStoreImpl)]
    impl CounterStore<
        TContractState, +HasComponent<TContractState>
    > of ICounterStore<ComponentState<TContractState>> {
        
        fn get_player_state(self: @ComponentState<TContractState>, user: ContractAddress) -> PlayerState {
            self.player_states.entry(user).read()
        }

        fn set_player_state(ref self: ComponentState<TContractState>, user: ContractAddress, state: PlayerState) {
            self.player_states.entry(user).write(state);
        }

        fn has_purchased_upgrade(self: @ComponentState<TContractState>, user: ContractAddress, upgrade_id: u32) -> bool {
            let purchases = self.user_purchases.entry(user);
            let len = purchases.len();
            let mut i = 0;
            while i < len {
                if purchases.at(i).read() == upgrade_id {
                    return true;
                }
                i += 1;
            };
            false
        }

        fn add_purchase(ref self: ComponentState<TContractState>, user: ContractAddress, upgrade_id: u32) {
            let mut purchases = self.user_purchases.entry(user);
            purchases.append().write(upgrade_id);
        }

        fn get_user_purchases(self: @ComponentState<TContractState>, user: ContractAddress) -> Array<u32> {
            let purchases = self.user_purchases.entry(user);
            let len = purchases.len();
            let mut result = ArrayTrait::new();
            let mut i = 0;
            while i < len {
                result.append(purchases.at(i).read());
                i += 1;
            };
            result
        }

        fn get_upgrade_config(self: @ComponentState<TContractState>, upgrade_id: u32) -> UpgradeConfig {
            self.upgrade_configs.entry(upgrade_id).read()
        }

        fn set_upgrade_config(ref self: ComponentState<TContractState>, upgrade_id: u32, config: UpgradeConfig) {
            self.upgrade_configs.entry(upgrade_id).write(config);
        }

        fn initialize_upgrades(ref self: ComponentState<TContractState>) {
            if self.initialized.read() {
                return;
            }

            // Initialize the 4 upgrades from the frontend
            self.upgrade_configs.entry(1).write(UpgradeConfig { id: 1, cost: 10, increment_value: 2 });
            self.upgrade_configs.entry(2).write(UpgradeConfig { id: 2, cost: 25, increment_value: 3 });
            self.upgrade_configs.entry(3).write(UpgradeConfig { id: 3, cost: 50, increment_value: 4 });
            self.upgrade_configs.entry(4).write(UpgradeConfig { id: 4, cost: 100, increment_value: 5 });
            
            self.initialized.write(true);
        }

        fn reset_player(ref self: ComponentState<TContractState>, user: ContractAddress) {
            let initial_state = PlayerState {
                count: 0,
                points: 0,
                increment_value: 1,
                decrement_value: 1,
            };
            self.player_states.entry(user).write(initial_state);
            // Clear user purchases by resetting the Vec
            let mut purchases = self.user_purchases.entry(user);
            // Note: In a real implementation, you might need a different approach to clear the Vec
        }
    }
}