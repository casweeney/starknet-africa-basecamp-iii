use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait};

use bank::{IBankDispatcher, IBankDispatcherTrait};
use bank::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use bank::Bank;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_can_deposit() {
    let bank_contract_address = deploy_contract("Bank");
    let bank_contract = IBankDispatcher { contract_address: bank_contract_address };

    let mock_token_contract_address = deploy_contract("MockToken");
    let token_contract = IERC20Dispatcher {contract_address: mock_token_contract_address};

    let caller: ContractAddress = starknet::contract_address_const::<0x123456789>();
    let mint_amount: u256 = 10000_u256;

    token_contract.mint(caller, mint_amount);
    assert(token_contract.balance_of(caller) == mint_amount, 'mint failed');

    start_cheat_caller_address(mock_token_contract_address, caller);
    let approve_amount = 100_u256;
    token_contract.approve(bank_contract_address, approve_amount);
    stop_cheat_caller_address(mock_token_contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(bank_contract_address, caller);
    let deposit_amount = 100_u256;
    bank_contract.deposit(mock_token_contract_address, deposit_amount);

    let expected_event = Bank::Event::DepositSuccessful(
        Bank::DepositSuccessful {
            user: caller,
            token_address: mock_token_contract_address,
            amount: 100
        }
    );

    spy.assert_emitted(@array![(bank_contract_address, expected_event)]);

    assert(token_contract.balance_of(caller) == mint_amount - deposit_amount, 'deposit failed');
    stop_cheat_caller_address(bank_contract_address);
}