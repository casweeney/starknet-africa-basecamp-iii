use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use setter_getter::{ISetterGetterDispatcher, ISetterGetterDispatcherTrait};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

#[test]
fn test_set_number_get_number() {
    let setter_getter_contract_address = deploy_contract("SetterGetter");

    let setter_getter_contract = ISetterGetterDispatcher { contract_address: setter_getter_contract_address };

    setter_getter_contract.set_number(20);

    let contract_number = setter_getter_contract.get_number();

    assert(contract_number == 20, 'set number failed');
}