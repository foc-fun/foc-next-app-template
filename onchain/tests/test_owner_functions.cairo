use starknet::ContractAddress;
use snforge_std::{declare, DeclareResultTrait, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address};
use snforge_std::{spy_events, EventSpyAssertionsTrait};

use onchain::counter::{
    ICounterGameDispatcher, ICounterGameDispatcherTrait
};

fn deploy_contract_with_owner(owner: ContractAddress) -> ICounterGameDispatcher {
    let contract = declare("CounterGame").unwrap().contract_class();
    let mut constructor_args = ArrayTrait::new();
    constructor_args.append(owner.into());
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    ICounterGameDispatcher { contract_address }
}

fn setup_test_addresses() -> (ContractAddress, ContractAddress, ContractAddress) {
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let alice: ContractAddress = 'alice'.try_into().unwrap();
    let bob: ContractAddress = 'bob'.try_into().unwrap();
    (owner, alice, bob)
}

#[test]
fn test_owner_is_set_correctly() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    assert(game.get_owner() == owner, 'Owner not set correctly');
}

#[test]
fn test_set_upgrade_config_by_owner() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Change first upgrade config
    game.set_upgrade_config(1, 15, 3);
    
    let upgrade = game.get_upgrade_config(1);
    assert(upgrade.cost == 15, 'Cost not updated');
    assert(upgrade.increment_value == 3, 'Increment not updated');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_set_upgrade_config_by_non_owner() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Try to change upgrade config as non-owner
    game.set_upgrade_config(1, 15, 3);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Upgrade does not exist',))]
fn test_set_upgrade_config_nonexistent() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Try to modify non-existent upgrade
    game.set_upgrade_config(99, 100, 10);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_add_new_upgrade() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Add a new upgrade with id 5
    game.add_new_upgrade(5, 200, 10);
    
    let upgrade = game.get_upgrade_config(5);
    assert(upgrade.id == 5, 'New upgrade id incorrect');
    assert(upgrade.cost == 200, 'New upgrade cost incorrect');
    assert(upgrade.increment_value == 10, 'New upgrade inc incorrect');
    
    // Check it appears in get_all_upgrades
    let all_upgrades = game.get_all_upgrades();
    assert(all_upgrades.len() == 5, 'Should have 5 upgrades now');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Upgrade already exists',))]
fn test_add_duplicate_upgrade() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Try to add duplicate upgrade
    game.add_new_upgrade(1, 100, 5);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_add_new_upgrade_by_non_owner() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Try to add upgrade as non-owner
    game.add_new_upgrade(5, 200, 10);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_remove_upgrade() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Remove upgrade 4
    game.remove_upgrade(4);
    
    let upgrade = game.get_upgrade_config(4);
    assert(upgrade.id == 0, 'Upgrade not removed');
    assert(upgrade.cost == 0, 'Cost not zeroed');
    assert(upgrade.increment_value == 0, 'Increment not zeroed');
    
    // Check it's removed from get_all_upgrades
    let all_upgrades = game.get_all_upgrades();
    assert(all_upgrades.len() == 3, 'Should have 3 upgrades now');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Upgrade does not exist',))]
fn test_remove_nonexistent_upgrade() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Try to remove non-existent upgrade
    game.remove_upgrade(99);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_remove_upgrade_by_non_owner() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Try to remove upgrade as non-owner
    game.remove_upgrade(1);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_transfer_ownership() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    // Transfer ownership to alice
    game.transfer_ownership(alice);
    
    assert(game.get_owner() == alice, 'Ownership not transferred');
    
    stop_cheat_caller_address(game.contract_address);
    
    // Now alice should be able to perform owner actions
    start_cheat_caller_address(game.contract_address, alice);
    
    game.set_upgrade_config(1, 20, 4);
    
    let upgrade = game.get_upgrade_config(1);
    assert(upgrade.cost == 20, 'Alice cannot modify as owner');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_transfer_ownership_by_non_owner() {
    let (owner, alice, bob) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, alice);
    
    // Try to transfer ownership as non-owner
    game.transfer_ownership(bob);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_event_upgrade_config_changed() {
    let (owner, _, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    let mut spy = spy_events();
    game.set_upgrade_config(1, 15, 3);
    
    spy.assert_emitted(@array![
        (
            game.contract_address,
            onchain::counter::CounterGame::Event::UpgradeConfigChanged(
                onchain::counter::CounterGame::UpgradeConfigChanged {
                    upgrade_id: 1,
                    cost: 15,
                    increment_value: 3
                }
            )
        )
    ]);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_event_ownership_transferred() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    start_cheat_caller_address(game.contract_address, owner);
    
    let mut spy = spy_events();
    game.transfer_ownership(alice);
    
    spy.assert_emitted(@array![
        (
            game.contract_address,
            onchain::counter::CounterGame::Event::OwnershipTransferred(
                onchain::counter::CounterGame::OwnershipTransferred {
                    previous_owner: owner,
                    new_owner: alice
                }
            )
        )
    ]);
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_modified_upgrade_affects_gameplay() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    // Alice earns points
    start_cheat_caller_address(game.contract_address, alice);
    let mut i: u32 = 0;
    while i < 10 {
        game.increment();
        i += 1;
    };
    stop_cheat_caller_address(game.contract_address);
    
    // Owner changes upgrade 1 to be cheaper
    start_cheat_caller_address(game.contract_address, owner);
    game.set_upgrade_config(1, 5, 2);
    stop_cheat_caller_address(game.contract_address);
    
    // Alice can now afford it with only 10 points
    start_cheat_caller_address(game.contract_address, alice);
    
    let can_afford = game.can_afford_upgrade(alice, 1);
    assert(can_afford, 'Should afford cheaper upgrade');
    
    let success = game.buy_upgrade(1);
    assert(success, 'Should buy cheaper upgrade');
    
    let state = game.get_player_state(alice);
    assert(state.points == 5, 'Should have 5 points left');
    assert(state.increment_value == 2, 'Increment should be 2');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_add_and_buy_new_upgrade() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    // Owner adds a new super upgrade that's more affordable
    start_cheat_caller_address(game.contract_address, owner);
    game.add_new_upgrade(10, 50, 20);
    stop_cheat_caller_address(game.contract_address);
    
    // Alice earns exactly 50 points
    start_cheat_caller_address(game.contract_address, alice);
    let mut i: u32 = 0;
    while i < 50 {
        game.increment();
        i += 1;
    };
    
    // Buy the super upgrade
    let success = game.buy_upgrade(10);
    assert(success, 'Should buy super upgrade');
    
    let state = game.get_player_state(alice);
    assert(state.points == 0, 'Should have 0 points left');
    assert(state.increment_value == 20, 'Should have 20x power');
    
    // Test the 20x power
    game.increment();
    let state = game.get_player_state(alice);
    assert(state.count == 70, 'Count should be 70');
    assert(state.points == 20, 'Should earn 20 points');
    
    stop_cheat_caller_address(game.contract_address);
}

#[test]
fn test_remove_upgrade_prevents_purchase() {
    let (owner, alice, _) = setup_test_addresses();
    let game = deploy_contract_with_owner(owner);
    
    // Owner removes upgrade 2
    start_cheat_caller_address(game.contract_address, owner);
    game.remove_upgrade(2);
    stop_cheat_caller_address(game.contract_address);
    
    // Alice tries to buy removed upgrade
    start_cheat_caller_address(game.contract_address, alice);
    let mut i: u32 = 0;
    while i < 30 {
        game.increment();
        i += 1;
    };
    
    let can_afford = game.can_afford_upgrade(alice, 2);
    assert(!can_afford, 'Should not afford removed');
    
    let success = game.buy_upgrade(2);
    assert(!success, 'Should not buy removed upgrade');
    
    let state = game.get_player_state(alice);
    assert(state.points == 30, 'Points should not change');
    
    stop_cheat_caller_address(game.contract_address);
}