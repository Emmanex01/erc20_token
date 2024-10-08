use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn get_name(self: @TContractState) -> ByteArray;
    fn get_symbol(self: @TContractState) -> ByteArray;
    fn get_decimals(self: @TContractState) -> u8;
    fn get_total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    );
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256);
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: u256);
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    );
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod ERC20 {
    use starknet::event::EventEmitter;
    use starknet::ContractAddress;
    use core::starknet::{storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}};
    use super::IERC20;
    const TOTAL_SUPPLY: u256 = 100_000_000;
    #[storage]
    struct Storage {
        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        total_supply: u256,
        balances: Map::<ContractAddress, u256>,
        allowances: Map::<(ContractAddress, ContractAddress), u256>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: ByteArray, symbol: ByteArray
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.total_supply.write(TOTAL_SUPPLY);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256,
    }

    #[abi(embed_v0)]
    impl ERC20IMPL of IERC20<ContractState> {
        fn get_name(self: @ContractState) -> ByteArray {
            self.name.read()
        }
        fn get_symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }
        fn get_decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }
        fn get_total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let sender = starknet::get_caller_address();
            let sender_balance = self.balances.read(sender);
            let recipient_balance = self.balances.read(recipient);
            assert(sender_balance >= amount, 'insufficient balance');
            self.balances.write(sender, sender_balance - amount);
            self.balances.write(recipient, recipient_balance + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount })
        }
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let caller = starknet::get_caller_address();
            assert(caller == sender, 'INVALID CALLER');
            let sender_balance = self.balances.read(sender);
            assert(sender_balance >= amount, 'insufficient balance');
            if (caller != sender) {
                assert!(self.allowances.read((sender, caller)) >= amount, "ERROR: UNAUTHORISED");
            }
            self.balances.write(sender, sender_balance - amount);

            let recipient_balance = self.balances.read(recipient);
            self.balances.write(recipient, recipient_balance + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount })
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let caller = starknet::get_caller_address();
            let allowed_person = (caller, spender);
            let prev_allowance = self.allowances.read(allowed_person);
            self.allowances.write(allowed_person, prev_allowance + amount);
            self.emit(Approval { owner: caller, spender, value: amount })
        }
        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) {
            let caller = starknet::get_caller_address();
            let allowed_person = (caller, spender);
            let prev_allowance = self.allowances.read(allowed_person);
            self.allowances.write(allowed_person, prev_allowance + added_value);
            self.emit(Approval { owner: caller, spender, value: added_value })
        }
        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) {
            let caller = starknet::get_caller_address();
            let allowed_person = (caller, spender);
            let prev_allowance = self.allowances.read(allowed_person);
            self.allowances.write(allowed_person, prev_allowance - subtracted_value);
            self.emit(Approval { owner: caller, spender, value: subtracted_value })
        }
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
        }
        fn mint(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.balances.write(account, amount);
        }
    }
}
