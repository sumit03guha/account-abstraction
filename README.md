# Account Abstraction Project

An implementation of account abstraction mechanisms using Solidity, featuring `SimpleAccount` contracts and integration with zkSync. This project demonstrates how to build, deploy, and test account abstraction contracts using Foundry, enabling more flexible account behaviors and customization of transaction validation logic.

## Introduction

Account abstraction allows for customizable account logic on the Ethereum blockchain. By abstracting the account model, developers can implement advanced functionalities like custom signature validation, meta-transactions, and enhanced security features. This project implements account abstraction concepts through the `SimpleAccount` contract and extends support for zkSync, providing a foundation for more advanced account behaviors and scalability solutions.

## Features

- **SimpleAccount Contract**: A basic implementation of an account that supports custom validation logic.
- **zkSync Integration**: Extended support for zkSync network with specific contracts and tests.
- **Deployment Scripts**: Automated deployment using Foundry scripts.
- **Comprehensive Testing**: A full suite of tests written in Solidity using Forge test framework.
- **Modular Configuration**: Easy-to-manage network configurations via `HelperConfig`.

## Project Structure

```
├── src/
│   ├── SimpleAccount.sol                    # Main EVM account contract.
│   ├── Errors.sol                           # Custom error definitions.
│   └── zksync/
│       ├── SimpleAccountZkSync.sol          # zkSync-specific account contract.
│       └── Errors.sol                       # Custom error definitions.
├── script/
│   ├── DeploySimpleAccount.s.sol            # Script to deploy SimpleAccount.
│   ├── HelperConfig.s.sol                   # Network configuration script.
│   └── NetworkConfig.sol                    # Network configuration data structure.
├── test/
│   ├── SimpleAccountTest.t.sol              # Test suite for SimpleAccount.
│   └── zksync/
│       └── SimpleAccountZkSyncTest.t.sol    # Tests for zkSync integration.
├── lib/                                     # External libraries and submodules.
│   ├── account-abstraction/                 # Account abstraction standards.
│   ├── forge-std/                           # Standard library for Forge.
│   ├── foundry-era-contracts/               # ERA contracts for Foundry.
│   └── openzeppelin-contracts/              # Standard security libraries.
├── foundry.toml                             # Foundry configuration file.
├── remappings.txt                           # Dependency remappings.
├── README.md                                # Project documentation.
└── ...                                      # Other configuration and helper files.
```

## Installation

### Prerequisites

- **Foundry**: Install Foundry by following the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation).
- **Git Submodules**: The project uses submodules for external libraries.

### Steps

1. **Clone the Repository**:

   ```shell
   git clone https://github.com/sumit03guha/account-abstraction
   cd account-abstraction
   ```

2. **Initialize Submodules**:

   ```shell
   git submodule update --init --recursive
   ```

3. **Install Dependencies**:

   ```shell
   forge install
   ```

4. **Build the Contracts**:

   ```shell
   forge build
   ```

## Usage

### Deploy Contracts

Use the provided deployment scripts to deploy the `SimpleAccount` contract.

```shell
forge script script/DeploySimpleAccount.s.sol --broadcast
```

> **Note**: You may need to provide additional flags such as `--rpc-url` and `--private-key` for network and account configurations.

### Run Tests

Execute the test suite to ensure contracts function as expected.

```shell
forge test --match-contract SimpleAccountTest
```

To run tests specifically for zkSync integration:

```shell
forge test --match-contract SimpleAccountZkSyncTest --zksync --zk-enable-eravm-extensions=true
```

### Configure Networks

The `HelperConfig` script sets up network configurations based on the chain ID.

- **Supported Networks**:
  - Anvil or Anvil-zksync (Local blockchain)
  - Sepolia
  - zkSync

### Format Code

Ensure code adheres to the style guidelines.

```shell
forge fmt
```

## zkSync Integration

This project includes support for zkSync, a Layer 2 scalability solution. The zkSync-specific contracts and tests are located in the `src/zksync/` and `test/zksync/` directories.

- **Contracts**:

  - `SimpleAccountZkSync.sol`: Account contract adapted for zkSync.
  - `Errors.sol`: Error definitions specific to zkSync.

- **Tests**:
  - `SimpleAccountZkSyncTest.t.sol`: Test suite for the zkSync account contract.

### Running zkSync Tests

```shell
forge test --match-contract SimpleAccountZkSyncTest --zksync --zk-enable-eravm-extensions=true
```

> **Note**: You may need to configure your Foundry settings to interact with zkSync's testnet or mainnet. Ensure that the appropriate RPC endpoints and chain IDs are set.

## Dependencies

- [Foundry](https://github.com/foundry-rs/foundry): Smart contract development toolchain.
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts): Standard library for secure smart contract development.
- [Account Abstraction Library](https://github.com/eth-infinitism/account-abstraction): Implements account abstraction functionalities.
- [Forge Std Library](https://github.com/foundry-rs/forge-std): Standard library for testing.
- [foundry-era-contracts](https://github.com/your-org/foundry-era-contracts): ERA contracts integration for Foundry.

## Configuration

The `foundry.toml` file contains project configurations. Key settings include:

- **Compiler Version**: Solidity `0.8.28`.
- **EVM Version**: `cancun`.
- **Optimizer**: Enabled with `200` runs.
- **Via-IR**: Enabled for Yul intermediate representation.

## Contributing

Contributions are welcome! Please open issues and submit pull requests for any improvements.

### Steps to Contribute

1. **Fork the Repository**.

2. **Create a New Branch**:

   ```shell
   git checkout -b feature/your-feature-name
   ```

3. **Commit Your Changes**:

   ```shell
   git commit -am 'Add some feature'
   ```

4. **Push to the Branch**:

   ```shell
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request**.

## Acknowledgements

- **Ethereum Foundation**: For the account abstraction EIPs and research.
- **zkSync Team**: For providing Layer 2 scalability solutions.
- **Foundry Team**: For providing a robust development environment.
- **OpenZeppelin**: For secure and reliable smart contract libraries.
