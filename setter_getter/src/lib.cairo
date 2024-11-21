#[starknet::interface]
pub trait ISetterGetter<TContractState> {
    fn set_number(ref self: TContractState, number: u256);
    fn get_number(self: @TContractState) -> u256;
}

#[starknet::contract]
mod SetterGetter {
    #[storage]
    struct Storage {
        number: u256
    }

    #[abi(embed_v0)]
    impl SetterGetterImpl of super::ISetterGetter<ContractState> {
        fn set_number(ref self: ContractState, number: u256) {
            self.number.write(number);
        }

        fn get_number(self: @ContractState) -> u256 {
            self.number.read()
        }
    }
}
