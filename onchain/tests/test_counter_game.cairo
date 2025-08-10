use starknet::ContractAddress;
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address};
use snforge_std::{spy_events, EventSpyAssertionsTrait};

use onchain::counter::{
    ICounterGameDispatcher, ICounterGameDispatcherTrait
};

fn deploy_contract() -> ICounterGameDispatcher {
    let contract = declare("CounterGame").unwrap().contract_class();
    let owner: ContractAddress = 'default_owner'.try_into().unwrap();
    let mut constructor_args = ArrayTrait::new();
    constructor_args.append(owner.into());
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    ICounterGameDispatcher { contract_address }
}

fn setup_test_addresses() -> (ContractAddress, ContractAddress, ContractAddress) {
    let alice: ContractAddress = 'alice'.try_into().unwrap();
    let bob: ContractAddress = 'bob'.try_into().unwrap();
    let charlie: ContractAddress = 'charlie'.try_into().unwrap();
    (alice, bob, charlie)
}

#[test]
fn test_initial_player_state() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    let state = game.get_player_state(alice);
    
    assert(state.count == 0, 'Initial count should be 0');
    assert(state.points == 0, 'Initial points should be 0');
    assert(state.increment_value == 1, 'Initial increment should be 1');
    assert(state.decrement_value == 1, 'Initial decrement should be 1');
}

#[test]
fn test_increment_action() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    // Set alice as caller
    start_cheat_caller_address(game.contract_address, alice);
    
    // Perform increment
    game.increment();
    
    let state = game.get_player_state(alice);
    assert(state.count == 1, 'Count should be 1 after inc');
    assert(state.points == 1, 'Points should be 1 after inc');
    
    // Increment again
    game.increment();
    
    let state = game.get_player_state(alice);
    assert(state.count == 2, 'Count should be 2 after 2 inc');
    assert(state.points == 2, 'Points should be 2 after 2 inc');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_decrement_action() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Increment to get some count
    game.increment();
    game.increment();
    game.increment();
    
    let state = game.get_player_state(alice);
    assert(state.count == 3, 'Count should be 3');
    assert(state.points == 3, 'Points should be 3');
    
    // Decrement
    game.decrement();
    
    let state = game.get_player_state(alice);
    assert(state.count == 2, 'Count should be 2 after dec');
    assert(state.points == 3, 'Points should stay 3 after dec');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_decrement_at_zero() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Decrement when count is 0
    game.decrement();
    
    let state = game.get_player_state(alice);
    assert(state.count == 0, 'Count should stay 0');
    assert(state.points == 0, 'Points should stay 0');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_reset_action() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Build up some state
    game.increment();
    game.increment();
    game.increment();
    
    let state = game.get_player_state(alice);
    assert(state.count == 3, 'Count should be 3');
    assert(state.points == 3, 'Points should be 3');
    
    // Reset
    game.reset();
    
    let state = game.get_player_state(alice);
    assert(state.count == 0, 'Count should be 0 after reset');
    assert(state.points == 0, 'Points should be 0 after reset');
    assert(state.increment_value == 1, 'Inc should be 1 after reset');
    assert(state.decrement_value == 1, 'Dec should be 1 after reset');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_get_all_upgrades() {
    let game = deploy_contract();
    
    let upgrades = game.get_all_upgrades();
    
    assert(upgrades.len() == 4, 'Should have 4 upgrades');
    
    // Check first upgrade
    let upgrade1 = *upgrades.at(0);
    assert(upgrade1.id == 1, 'First upgrade id should be 1');
    assert(upgrade1.cost == 10, 'First upgrade cost should be 10');
    assert(upgrade1.increment_value == 2, 'First upgrade inc should be 2');
    
    // Check second upgrade
    let upgrade2 = *upgrades.at(1);
    assert(upgrade2.id == 2, 'Second upgrade id should be 2');
    assert(upgrade2.cost == 25, 'Second upgrade cost: 25');
    assert(upgrade2.increment_value == 3, 'Second upgrade inc should be 3');
    
    // Check third upgrade
    let upgrade3 = *upgrades.at(2);
    assert(upgrade3.id == 3, 'Third upgrade id should be 3');
    assert(upgrade3.cost == 50, 'Third upgrade cost should be 50');
    assert(upgrade3.increment_value == 4, 'Third upgrade inc should be 4');
    
    // Check fourth upgrade
    let upgrade4 = *upgrades.at(3);
    assert(upgrade4.id == 4, 'Fourth upgrade id should be 4');
    assert(upgrade4.cost == 100, 'Fourth upgrade cost 100');
    assert(upgrade4.increment_value == 5, 'Fourth upgrade inc should be 5');
}

#[test]
fn test_buy_first_upgrade() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn points
    let mut i: u32 = 0;
    while i < 10 {
        game.increment();
        i += 1;
    };
    
    let state = game.get_player_state(alice);
    assert(state.points == 10, 'Should have 10 points');
    
    // Buy first upgrade
    let success = game.buy_upgrade(1);
    assert(success, 'Upgrade purchase should succeed');
    
    let state = game.get_player_state(alice);
    assert(state.points == 0, 'Points should be 0 after buy');
    assert(state.increment_value == 2, 'Inc should be 2 after upgrade');
    assert(state.decrement_value == 2, 'Dec should be 2 after upgrade');
    
    // Test upgraded increment
    game.increment();
    let state = game.get_player_state(alice);
    assert(state.count == 12, 'Count should be 12 (10+2)');
    assert(state.points == 2, 'Points should be 2');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_cannot_buy_upgrade_twice() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn enough points
    let mut i: u32 = 0;
    while i < 20 {
        game.increment();
        i += 1;
    };
    
    // Buy first upgrade
    let success = game.buy_upgrade(1);
    assert(success, 'First purchase should succeed');
    
    // Try to buy again
    let success = game.buy_upgrade(1);
    assert(!success, 'Second purchase should fail');
    
    // Check player still has the upgrade
    assert(game.has_purchased_upgrade(alice, 1), 'Should have upgrade');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_cannot_afford_upgrade() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Only earn 5 points
    let mut i: u32 = 0;
    while i < 5 {
        game.increment();
        i += 1;
    };
    
    // Try to buy upgrade that costs 10
    let success = game.buy_upgrade(1);
    assert(!success, 'Purchase should fail');
    
    let state = game.get_player_state(alice);
    assert(state.points == 5, 'Points should still be 5');
    assert(state.increment_value == 1, 'Inc should still be 1');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_buy_multiple_upgrades() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn 35 points (enough for upgrade 1 and 2)
    let mut i: u32 = 0;
    while i < 35 {
        game.increment();
        i += 1;
    };
    
    // Buy first upgrade (cost 10)
    let success = game.buy_upgrade(1);
    assert(success, 'First upgrade should succeed');
    
    let state = game.get_player_state(alice);
    assert(state.points == 25, 'Should have 25 points left');
    assert(state.increment_value == 2, 'Inc should be 2');
    
    // Buy second upgrade (cost 25)
    let success = game.buy_upgrade(2);
    assert(success, 'Second upgrade should succeed');
    
    let state = game.get_player_state(alice);
    assert(state.points == 0, 'Should have 0 points left');
    assert(state.increment_value == 3, 'Inc should be 3');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_can_afford_upgrade() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Initially cannot afford
    assert(!game.can_afford_upgrade(alice, 1), 'Should not afford initially');
    
    // Earn 10 points
    let mut i: u32 = 0;
    while i < 10 {
        game.increment();
        i += 1;
    };
    
    // Now can afford
    assert(game.can_afford_upgrade(alice, 1), 'Should afford with 10 points');
    
    // Buy it
    game.buy_upgrade(1);
    
    // Cannot afford anymore (already purchased)
    assert(!game.can_afford_upgrade(alice, 1), 'Should not afford if owned');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_get_user_purchases() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Initially no purchases
    let purchases = game.get_user_purchases(alice);
    assert(purchases.len() == 0, 'Should have no purchases');
    
    // Earn points and buy upgrades
    let mut i: u32 = 0;
    while i < 100 {
        game.increment();
        i += 1;
    };
    
    game.buy_upgrade(1);
    game.buy_upgrade(3);
    
    let purchases = game.get_user_purchases(alice);
    assert(purchases.len() == 2, 'Should have 2 purchases');
    assert(*purchases.at(0) == 1, 'First purchase should be 1');
    assert(*purchases.at(1) == 3, 'Second purchase should be 3');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_multiple_players() {
    let game = deploy_contract();
    let (alice, bob, _) = setup_test_addresses();
    
    // Alice plays
    start_cheat_caller_address(game.contract_address, alice);
    game.increment();
    game.increment();
    stop_cheat_caller_address(game.contract_address);
    
    // Bob plays
    start_cheat_caller_address(game.contract_address, bob);
    game.increment();
    stop_cheat_caller_address(game.contract_address);
    
    // Check states are separate
    let alice_state = game.get_player_state(alice);
    let bob_state = game.get_player_state(bob);
    
    assert(alice_state.count == 2, 'Alice should have count 2');
    assert(alice_state.points == 2, 'Alice should have 2 points');
    assert(bob_state.count == 1, 'Bob should have count 1');
    assert(bob_state.points == 1, 'Bob should have 1 point');
}

#[test]
fn test_invalid_upgrade_id() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn points
    let mut i: u32 = 0;
    while i < 100 {
        game.increment();
        i += 1;
    };
    
    // Try to buy non-existent upgrade
    let success = game.buy_upgrade(99);
    assert(!success, 'Invalid upgrade should fail');
    
    let state = game.get_player_state(alice);
    assert(state.points == 100, 'Points should not change');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_increment_with_upgraded_power() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn points for mega upgrade
    let mut i: u32 = 0;
    while i < 100 {
        game.increment();
        i += 1;
    };
    
    // Buy mega upgrade (5x power)
    game.buy_upgrade(4);
    
    let state = game.get_player_state(alice);
    assert(state.increment_value == 5, 'Inc should be 5');
    
    // Test new increment power
    let count_before = state.count;
    game.increment();
    
    let state = game.get_player_state(alice);
    assert(state.count == count_before + 5, 'Count should increase by 5');
    assert(state.points == 5, 'Should earn 5 points');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_decrement_with_upgraded_power() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn points and buy upgrade
    let mut i: u32 = 0;
    while i < 25 {
        game.increment();
        i += 1;
    };
    
    game.buy_upgrade(2); // 3x power
    
    // Increment more to test decrement
    game.increment(); // +3
    game.increment(); // +3
    
    let state = game.get_player_state(alice);
    let count_before = state.count;
    
    // Decrement with 3x power
    game.decrement();
    
    let state = game.get_player_state(alice);
    assert(state.count == count_before - 3, 'Count should decrease by 3');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_event_counter_incremented() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    let mut spy = spy_events();
    
    start_cheat_caller_address(game.contract_address, alice);
    game.increment();
    stop_cheat_caller_address(game.contract_address);
    
    spy.assert_emitted(@array![
        (
            game.contract_address,
            onchain::counter::CounterGame::Event::CounterIncremented(
                onchain::counter::CounterGame::CounterIncremented {
                    user: alice,
                    new_count: 1,
                    points_earned: 1
                }
            )
        )
    ]);
}

#[test]
fn test_event_upgrade_purchased() {
    let game = deploy_contract();
    let (alice, _, _) = setup_test_addresses();
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Earn points
    let mut i: u32 = 0;
    while i < 10 {
        game.increment();
        i += 1;
    };
    
    let mut spy = spy_events();
    game.buy_upgrade(1);
    stop_cheat_caller_address(game.contract_address);
    
    spy.assert_emitted(@array![
        (
            game.contract_address,
            onchain::counter::CounterGame::Event::UpgradePurchased(
                onchain::counter::CounterGame::UpgradePurchased {
                    user: alice,
                    upgrade_id: 1,
                    cost: 10,
                    new_increment_value: 2
                }
            )
        )
    ]);
}