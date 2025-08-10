use starknet::ContractAddress;
use super::types::{PlayerState, CounterIncremented, CounterDecremented, PlayerReset};

#[starknet::interface]
pub trait ICounterActions<TContractState> {
    // Core game actions
    fn increment(ref self: TContractState);
    fn decrement(ref self: TContractState);
    fn reset(ref self: TContractState);
    
    // View functions
    fn get_player_state(self: @TContractState, user: ContractAddress) -> PlayerState;
    fn get_current_count(self: @TContractState, user: ContractAddress) -> u32;
    fn get_current_points(self: @TContractState, user: ContractAddress) -> u32;
}

#[starknet::component]
pub mod CounterActionsComponent {
    use starknet::{ContractAddress, get_caller_address};
    use super::{ICounterActions, PlayerState, CounterIncremented, CounterDecremented, PlayerReset};
    use super::super::store::{ICounterStore, CounterStoreComponent};

    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncremented: CounterIncremented,
        CounterDecremented: CounterDecremented,
        PlayerReset: PlayerReset,
    }

    #[embeddable_as(CounterActionsImpl)]
    impl CounterActions<
        TContractState,
        +HasComponent<TContractState>,
        impl Store: CounterStoreComponent::HasComponent<TContractState>,
        +Drop<TContractState>
    > of ICounterActions<ComponentState<TContractState>> {

        fn increment(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            let mut store = get_dep_component_mut!(ref self, CounterStoreComponent);
            let mut state = store.get_player_state(caller);
            
            // If this is the first action, initialize with default state
            if state.count == 0 && state.points == 0 && state.increment_value == 0 {
                state = PlayerState {
                    count: 0,
                    points: 0,
                    increment_value: 1,
                    decrement_value: 1,
                };
            }
            
            // Update count and award points
            state.count += state.increment_value;
            state.points += state.increment_value;
            
            store.set_player_state(caller, state);
            
            self.emit(CounterIncremented {
                user: caller,
                new_count: state.count,
                points_earned: state.increment_value,
            });
        }

        fn decrement(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            let mut store = get_dep_component_mut!(ref self, CounterStoreComponent);
            let mut state = store.get_player_state(caller);
            
            // If this is the first action, initialize with default state  
            if state.count == 0 && state.points == 0 && state.increment_value == 0 {
                state = PlayerState {
                    count: 0,
                    points: 0,
                    increment_value: 1,
                    decrement_value: 1,
                };
            }
            
            // Update count (don't award points for decrement)
            if state.count >= state.decrement_value {
                state.count -= state.decrement_value;
            } else {
                state.count = 0;
            }
            
            store.set_player_state(caller, state);
            
            self.emit(CounterDecremented {
                user: caller,
                new_count: state.count,
            });
        }

        fn reset(ref self: ComponentState<TContractState>) {
            let caller = get_caller_address();
            let mut store = get_dep_component_mut!(ref self, CounterStoreComponent);
            
            store.reset_player(caller);
            
            self.emit(PlayerReset {
                user: caller,
            });
        }

        fn get_player_state(self: @ComponentState<TContractState>, user: ContractAddress) -> PlayerState {
            let store = get_dep_component!(self, CounterStoreComponent);
            let state = store.get_player_state(user);
            
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

        fn get_current_count(self: @ComponentState<TContractState>, user: ContractAddress) -> u32 {
            self.get_player_state(user).count
        }

        fn get_current_points(self: @ComponentState<TContractState>, user: ContractAddress) -> u32 {
            self.get_player_state(user).points
        }
    }
}