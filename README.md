# Pixotchi Smart Contracts

This repository contains the smart contracts for the Pixotchi project, including `Claim.sol`, `Claimer.sol`, and `SpinGame.sol`. These contracts are designed to handle various functionalities such as claiming tokens, managing claims, and playing a spin game with NFTs.

## Contracts Overview

### Claim.sol

The `Claim` contract is responsible for handling the redemption of vouchers using EIP-712 signatures. It ensures that only valid signatures from a designated signer can redeem the vouchers.

- **Signer Management**: The contract sets the deployer as the initial signer.
- **Redeem Function**: Users can redeem vouchers by providing a valid signature. The contract verifies the signature against the stored signer address.
- **Hashing Function**: The contract provides a function to get the EIP-712 hash of a given struct.

### Claimer.sol

The `Claimer` contract manages the claiming process for various types of claims such as airdrops and referrals. It uses EIP-712 signatures to verify the authenticity of claims.

- **Initialization**: The contract is initialized with the token address, signer address, and vault address.
- **Claim Types**: The contract supports multiple claim types and allows the owner to add new claim types.
- **Claim Function**: Users can claim tokens by providing the amount, nonce, signature, and claim type. The contract verifies the signature and ensures the claim is valid before transferring tokens from the vault to the user.
- **Nonce Management**: The contract tracks nonces for each user to prevent replay attacks.
- **Enable/Disable Claims**: The owner can enable or disable the claiming functionality.

### SpinGame.sol

The `SpinGame` contract allows users to play a spin game with their NFTs. The game provides various rewards based on random selections.

- **Initialization**: The contract is initialized with the address of the Pixotchi NFT contract.
- **Cooldown Management**: The contract enforces a cooldown period between plays for each NFT.
- **Rewards**: The contract supports various types of rewards, including point adjustments and time extensions. Rewards can be percentage-based or fixed values.
- **Play Function**: Users can play the game by providing their NFT ID and a seed value. The contract verifies the ownership and status of the NFT before applying the rewards.
- **Random Number Generation**: The contract includes multiple methods for generating random numbers and retries to ensure randomness.

## Usage

### Claim.sol

1. Deploy the `Claim` contract.
2. Set the signer address.
3. Users can call the `redeem` function with a valid signature to redeem their vouchers.

### Claimer.sol

1. Deploy the `Claimer` contract and initialize it with the token address, signer address, and vault address.
2. Add claim types using the `addClaimType` function.
3. Users can call the `claim` function with the required parameters to claim their tokens.

### SpinGame.sol

1. Deploy the `SpinGame` contract and initialize it with the Pixotchi NFT contract address.
2. Users can call the `play` function with their NFT ID and a seed value to play the game and receive rewards.

## Security Considerations

- Ensure that the signer addresses are securely managed and not compromised.
- Regularly audit the contracts to identify and fix potential vulnerabilities.
- Use secure random number generation methods to prevent manipulation of game outcomes.

## License

These contracts are licensed under the MIT License. See the `LICENSE` file for more details.

## Contact

For more information, visit our [website](https://pixotchi.tech/) or follow us on [Twitter](https://twitter.com/pixotchi).
