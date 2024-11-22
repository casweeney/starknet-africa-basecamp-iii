pub mod interfaces;
pub mod mocks;

use starknet::ContractAddress;

#[starknet::interface]
pub trait IBank<TContractState> {
    fn deposit(ref self: TContractState, token_address: ContractAddress, amount: u256);
    fn withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod Bank {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess,Map, StoragePathEntry};
    use crate::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};


    #[storage]
    struct Storage {
        // (user, token) -> amount
        balance: Map<(ContractAddress, ContractAddress), u256>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        DepositSuccessful: DepositSuccessful,
        WithdrawSuccessful: WithdrawSuccessful
    }

    #[derive(Drop, starknet::Event)]
    pub struct DepositSuccessful {
        pub user: ContractAddress,
        pub token_address: ContractAddress,
        pub amount: u256
    }

    #[derive(Drop, starknet::Event)]
    pub struct WithdrawSuccessful {
        pub user: ContractAddress,
        pub token_address: ContractAddress,
        pub amount: u256
    }

    #[abi(embed_v0)]
    impl BankImpl of super::IBank<ContractState> {
        fn deposit(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            assert(amount > 0, 'zero detected');
            let token = IERC20Dispatcher {contract_address: token_address};

            assert(token.balance_of(caller) >= amount, 'insufficient balance');

            let transfer = token.transfer_from(caller, this_contract, amount);

            assert(transfer, 'transfer failed');

            let prev_balance = self.balance.entry((caller, token_address)).read();

            self.balance.entry((caller, token_address)).write(prev_balance + amount);

            self.emit(DepositSuccessful {
                user: caller,
                token_address,
                amount
            });
        }

        fn withdraw(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(amount > 0, 'zero detected');
            let token = IERC20Dispatcher {contract_address: token_address};

            let user_balance = self.balance.entry((caller, token_address)).read();

            assert(amount <= user_balance, 'not enough balance');

            self.balance.entry((caller, token_address)).write(user_balance - amount);

            token.transfer(caller, amount);

            self.emit(WithdrawSuccessful {
                user: caller,
                token_address,
                amount
            });
        }
    }
}
