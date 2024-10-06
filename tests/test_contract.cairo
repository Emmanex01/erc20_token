use core::starknet::{ContractAddress, contract_address_const}; // imports contractaddress data type from core library
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait
}; // snforge library allows us to locally declare and deploy our contract
use my_erc20_token::erc20::{
    IERC20Dispatcher, IERC20DispatcherTrait
}; // import our erc20 contract using dispatcher function
// This struct represents the contructor arguments
#[derive(Drop, Serde)]
struct ERC20Args {
    name: ByteArray,
    symbol: ByteArray,
}

// A function that declare and deploy our contract then generate an address
fn deploy_contract(name: ByteArray) -> ContractAddress {
    // declare our contract to generate class hash
    let class_hash = declare(name).unwrap().contract_class();
    // instantiate our struct
    let args = ERC20Args { name: "EMMA TOKEN", symbol: "BLOCK" };
    // array to store the args struct
    let mut constructor_args = array![];
    // conversion of ByteArray to felt using serialization method
    args.serialize(ref constructor_args);
    //deploy using classhash
    let (address, _) = class_hash.deploy(@constructor_args).unwrap();
    address
}

#[test]
fn deploy_erc20() {
    // call and store the contract address
    let contract_address = deploy_contract("ERC20");
    // import our contract for testing
    let erc20 = IERC20Dispatcher { contract_address };
    //  check if the name you passed as arg to the constructor function is the as "EMMA TOKEN"
    assert!(erc20.get_name() == "EMMA TOKEN", "INVALID NAME");
}

#[test]
fn deployed_symbol() {
    // call and store the contract address
    let contract_address = deploy_contract("ERC20");
    // import our contract for testing
    let erc20 = IERC20Dispatcher { contract_address };
    //  check if the name you passed as arg to the constructor function is the as "EMMA TOKEN"
    assert!(erc20.get_symbol() == "BLOCK", "INVALID SYMBOL");
}

#[test]
fn test_mint() {
    // call and store the contract address
    let contract_address = deploy_contract("ERC20");
    // import our contract for testing
    let erc20 = IERC20Dispatcher { contract_address };
    // create a fake account using contract_address_const library
    let account =contract_address_const::<'Tochi'>();
    erc20.mint(account, 3000);
    assert!(erc20.balance_of(account) == 3000, "INCORRECT BALANCE");
}


