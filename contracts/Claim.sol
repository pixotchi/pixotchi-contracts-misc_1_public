// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "hardhat/console.sol";

contract Claim is EIP712("PixelClaimer", "1") {
    address public signer;

    /// @notice Represents an error reason when the signature for the voucher is invalid.
    error InvalidSigner();

    constructor()
    {
        signer = msg.sender;
    }

    function redeem(bytes memory signature) public {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Mail(address to,string contents)"),
            mailTo,
            keccak256(bytes(mailContents))
        )));
        address signer = ECDSA.recover(digest, signature);
    }

    function getHashTypedDataV4(bytes32 structHash) external view returns(bytes32){
        return _hashTypedDataV4(structHash);
    }
}
