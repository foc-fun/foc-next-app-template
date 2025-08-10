use starknet::ContractAddress;
use super::types::{UpgradeConfig, UpgradePurchased};

#[starknet::interface]
pub trait ICounterUpgrades<TContractState> {
    // Upgrade management
    fn buy_upgrade(ref self: TContractState, upgrade_id: u32) -> bool;
    fn get_upgrade_config(self: @TContractState, upgrade_id: u32) -> UpgradeConfig;
    fn has_purchased_upgrade(self: @TContractState, user: ContractAddress, upgrade_id: u32) -> bool;
    fn get_user_purchases(self: @TContractState, user: ContractAddress) -> Array<u32>;
    
    // View functions
    fn get_all_upgrades(self: @TContractState) -> Array<UpgradeConfig>;
    fn can_afford_upgrade(self: @TContractState, user: ContractAddress, upgrade_id: u32) -> bool;
}

#[starknet::component]
pub mod CounterUpgradesComponent {
    use starknet::{ContractAddress, get_caller_address};
    use super::{ICounterUpgrades, UpgradeConfig, UpgradePurchased};
    use super::super::store::{ICounterStore, CounterStoreComponent};
    use super::super::types::PlayerState;

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        UpgradePurchased: UpgradePurchased,
    }

    #[embeddable_as(CounterUpgradesImpl)]
    impl CounterUpgrades<
        TContractState,
        +HasComponent<TContractState>,
        +HasComponent<TContractState, CounterStoreComponent::ComponentState<TContractState>>,
        +Drop<TContractState>
    > of ICounterUpgrades<ComponentState<TContractState>> {

        fn buy_upgrade(ref self: ComponentState<TContractState>, upgrade_id: u32) -> bool {
            let caller = get_caller_address();
            let mut store = get_dep_component_mut!(ref self, CounterStoreComponent);
            
            // Check if upgrade exists
            let upgrade_config = store.get_upgrade_config(upgrade_id);
            if upgrade_config.id == 0 {
                return false; // Upgrade doesn't exist
            }
            
            // Check if already purchased
            if store.has_purchased_upgrade(caller, upgrade_id) {
                return false; // Already purchased
            }
            
            // Get player state
            let mut state = store.get_player_state(caller);
            
            // Initialize if needed
            if state.count == 0 && state.points == 0 && state.increment_value == 0 {
                state = PlayerState {
                    count: 0,
                    points: 0,
                    increment_value: 1,
                    decrement_value: 1,
                };
            }
            
            // Check if player can afford
            if state.points < upgrade_config.cost {
                return false; // Can't afford
            }
            
            // Process purchase
            state.points -= upgrade_config.cost;
            state.increment_value = upgrade_config.increment_value;
            state.decrement_value = upgrade_config.increment_value;
            
            // Update state
            store.set_player_state(caller, state);
            store.add_purchase(caller, upgrade_id);
            
            self.emit(UpgradePurchased {
                user: caller,
                upgrade_id,
                cost: upgrade_config.cost,
                new_increment_value: upgrade_config.increment_value,
            });
            
            true
        }

        fn get_upgrade_config(self: @ComponentState<TContractState>, upgrade_id: u32) -> UpgradeConfig {
            let store = get_dep_component!(self, CounterStoreComponent);
            store.get_upgrade_config(upgrade_id)
        }

        fn has_purchased_upgrade(self: @ComponentState<TContractState>, user: ContractAddress, upgrade_id: u32) -> bool {
            let store = get_dep_component!(self, CounterStoreComponent);
            store.has_purchased_upgrade(user, upgrade_id)
        }

        fn get_user_purchases(self: @ComponentState<TContractState>, user: ContractAddress) -> Array<u32> {
            let store = get_dep_component!(self, CounterStoreComponent);
            store.get_user_purchases(user)
        }

        fn get_all_upgrades(self: @ComponentState<TContractState>) -> Array<UpgradeConfig> {
            let store = get_dep_component!(self, CounterStoreComponent);
            let mut upgrades = ArrayTrait::new();
            
            // Get all 4 upgrades
            let mut i = 1_u32;
            while i <= 4 {
                let config = store.get_upgrade_config(i);
                if config.id != 0 {
                    upgrades.append(config);
                }
                i += 1;
            };
            
            upgrades
        }

        fn can_afford_upgrade(self: @ComponentState<TContractState>, user: ContractAddress, upgrade_id: u32) -> bool {
            let store = get_dep_component!(self, CounterStoreComponent);
            let upgrade_config = store.get_upgrade_config(upgrade_id);
            let state = store.get_player_state(user);
            
            if upgrade_config.id == 0 {
                return false; // Upgrade doesn't exist
            }
            
            if store.has_purchased_upgrade(user, upgrade_id) {
                return false; // Already purchased
            }
            
            state.points >= upgrade_config.cost
        }
    }
}