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

#[derive(Copy, Drop, Serde)]
pub struct CounterIncremented {
    pub user: ContractAddress,
    pub new_count: u32,
    pub points_earned: u32,
}

#[derive(Copy, Drop, Serde)]
pub struct CounterDecremented {
    pub user: ContractAddress,
    pub new_count: u32,
}

#[derive(Copy, Drop, Serde)]
pub struct UpgradePurchased {
    pub user: ContractAddress,
    pub upgrade_id: u32,
    pub cost: u32,
    pub new_increment_value: u32,
}

#[derive(Copy, Drop, Serde)]
pub struct PlayerReset {
    pub user: ContractAddress,
}