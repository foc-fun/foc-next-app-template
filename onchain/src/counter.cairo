use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct PlayerState {
    pub count: u32,
    pub points: u32,
    pub increment_value: u32,
    pub decrement_value: u32,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct UpgradeConfig {
    pub id: u32,
    pub cost: u32,
    pub increment_value: u32,
}

#[starknet::interface]
pub trait ICounterGame<TContractState> {
    // Core game actions
    fn increment(ref self: TContractState);
    fn decrement(ref self: TContractState);
    fn reset(ref self: TContractState);
    
    // Upgrade actions
    fn buy_upgrade(ref self: TContractState, upgrade_id: u32) -> bool;
    
    // View functions
    fn get_player_state(self: @TContractState, user: ContractAddress) -> PlayerState;
    fn get_current_count(self: @TContractState, user: ContractAddress) -> u32;
    fn get_current_points(self: @TContractState, user: ContractAddress) -> u32;
    fn get_upgrade_config(self: @TContractState, upgrade_id: u32) -> UpgradeConfig;
    fn get_all_upgrades(self: @TContractState) -> Array<UpgradeConfig>;
    fn has_purchased_upgrade(self: @TContractState, user: ContractAddress, upgrade_id: u32) -> bool;
    fn get_user_purchases(self: @TContractState, user: ContractAddress) -> Array<u32>;
    fn can_afford_upgrade(self: @TContractState, user: ContractAddress, upgrade_id: u32) -> bool;
}

#[starknet::contract]
pub mod CounterGame {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry,
        Map
    };
    use super::{ICounterGame, PlayerState, UpgradeConfig};

    #[storage]
    struct Storage {
        player_states: Map<ContractAddress, PlayerState>,
        user_purchases: Map<(ContractAddress, u32), bool>,
        upgrade_configs: Map<u32, UpgradeConfig>,
        initialized: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncremented: CounterIncremented,
        CounterDecremented: CounterDecremented,
        UpgradePurchased: UpgradePurchased,
        PlayerReset: PlayerReset,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterIncremented {
        pub user: ContractAddress,
        pub new_count: u32,
        pub points_earned: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterDecremented {
        pub user: ContractAddress,
        pub new_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UpgradePurchased {
        pub user: ContractAddress,
        pub upgrade_id: u32,
        pub cost: u32,
        pub new_increment_value: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PlayerReset {
        pub user: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self._initialize_upgrades();
    }

    #[abi(embed_v0)]
    impl CounterGameImpl of ICounterGame<ContractState> {
        fn increment(ref self: ContractState) {
            let caller = get_caller_address();
            let mut state = self._get_player_state(caller);
            
            // Update count and award points
            state.count += state.increment_value;
            state.points += state.increment_value;
            
            self.player_states.entry(caller).write(state);
            
            self.emit(CounterIncremented {
                user: caller,
                new_count: state.count,
                points_earned: state.increment_value,
            });
        }

        fn decrement(ref self: ContractState) {
            let caller = get_caller_address();
            let mut state = self._get_player_state(caller);
            
            // Update count (don't award points for decrement)
            if state.count >= state.decrement_value {
                state.count -= state.decrement_value;
            } else {
                state.count = 0;
            }
            
            self.player_states.entry(caller).write(state);
            
            self.emit(CounterDecremented {
                user: caller,
                new_count: state.count,
            });
        }

        fn reset(ref self: ContractState) {
            let caller = get_caller_address();
            
            let initial_state = PlayerState {
                count: 0,
                points: 0,
                increment_value: 1,
                decrement_value: 1,
            };
            
            self.player_states.entry(caller).write(initial_state);
            
            self.emit(PlayerReset {
                user: caller,
            });
        }

        fn buy_upgrade(ref self: ContractState, upgrade_id: u32) -> bool {
            let caller = get_caller_address();
            
            // Check if upgrade exists
            let upgrade_config = self.upgrade_configs.entry(upgrade_id).read();
            if upgrade_config.id == 0 {
                return false; // Upgrade doesn't exist
            }
            
            // Check if already purchased
            if self._has_purchased_upgrade(caller, upgrade_id) {
                return false; // Already purchased
            }
            
            // Get player state
            let mut state = self._get_player_state(caller);
            
            // Check if player can afford
            if state.points < upgrade_config.cost {
                return false; // Can't afford
            }
            
            // Process purchase
            state.points -= upgrade_config.cost;
            state.increment_value = upgrade_config.increment_value;
            state.decrement_value = upgrade_config.increment_value;
            
            // Update state
            self.player_states.entry(caller).write(state);
            
            // Mark as purchased
            self.user_purchases.entry((caller, upgrade_id)).write(true);
            
            self.emit(UpgradePurchased {
                user: caller,
                upgrade_id,
                cost: upgrade_config.cost,
                new_increment_value: upgrade_config.increment_value,
            });
            
            true
        }

        fn get_player_state(self: @ContractState, user: ContractAddress) -> PlayerState {
            self._get_player_state(user)
        }

        fn get_current_count(self: @ContractState, user: ContractAddress) -> u32 {
            self._get_player_state(user).count
        }

        fn get_current_points(self: @ContractState, user: ContractAddress) -> u32 {
            self._get_player_state(user).points
        }

        fn get_upgrade_config(self: @ContractState, upgrade_id: u32) -> UpgradeConfig {
            self.upgrade_configs.entry(upgrade_id).read()
        }

        fn get_all_upgrades(self: @ContractState) -> Array<UpgradeConfig> {
            let mut upgrades = ArrayTrait::new();
            
            // Get all 4 upgrades
            let mut i = 1_u32;
            while i <= 4 {
                let config = self.upgrade_configs.entry(i).read();
                if config.id != 0 {
                    upgrades.append(config);
                }
                i += 1;
            };
            
            upgrades
        }

        fn has_purchased_upgrade(self: @ContractState, user: ContractAddress, upgrade_id: u32) -> bool {
            self._has_purchased_upgrade(user, upgrade_id)
        }

        fn get_user_purchases(self: @ContractState, user: ContractAddress) -> Array<u32> {
            let mut result = ArrayTrait::new();
            
            // Check all possible upgrades (1-4)
            let mut i = 1_u32;
            while i <= 4 {
                if self.user_purchases.entry((user, i)).read() {
                    result.append(i);
                }
                i += 1;
            };
            
            result
        }

        fn can_afford_upgrade(self: @ContractState, user: ContractAddress, upgrade_id: u32) -> bool {
            let upgrade_config = self.upgrade_configs.entry(upgrade_id).read();
            let state = self._get_player_state(user);
            
            if upgrade_config.id == 0 {
                return false; // Upgrade doesn't exist
            }
            
            if self._has_purchased_upgrade(user, upgrade_id) {
                return false; // Already purchased
            }
            
            state.points >= upgrade_config.cost
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _get_player_state(self: @ContractState, user: ContractAddress) -> PlayerState {
            let state = self.player_states.entry(user).read();
            
            // Return initialized state if empty
            if state.count == 0 && state.points == 0 && state.increment_value == 0 {
                PlayerState {
                    count: 0,
                    points: 0,
                    increment_value: 1,
                    decrement_value: 1,
                }
            } else {
                state
            }
        }

        fn _has_purchased_upgrade(self: @ContractState, user: ContractAddress, upgrade_id: u32) -> bool {
            self.user_purchases.entry((user, upgrade_id)).read()
        }

        fn _initialize_upgrades(ref self: ContractState) {
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
    }
}