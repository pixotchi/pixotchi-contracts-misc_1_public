// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
/*

.-------. .-./`) _____     __   ,-----.  ,---------.   _______   .---.  .---..-./`)
\  _(`)_ \\ .-.')\   _\   /  /.'  .-,  '.\          \ /   __  \  |   |  |_ _|\ .-.')
| (_ o._)|/ `-' \.-./ ). /  '/ ,-.|  \ _ \`--.  ,---'| ,_/  \__) |   |  ( ' )/ `-' \
|  (_,_) / `-'`"`\ '_ .') .';  \  '_ /  | :  |   \ ,-./  )       |   '-(_{;}_)`-'`"`
|   '-.-'  .---.(_ (_) _) ' |  _`,/ \ _/  |  :_ _: \  '_ '`)     |      (_,_) .---.
|   |      |   |  /    \   \: (  '\_/ \   ;  (_I_)  > (_)  )  __ | _ _--.   | |   |
|   |      |   |  `-'`-'    \\ `"/  \  ) /  (_(=)_)(  .  .-'_/  )|( ' ) |   | |   |
/   )      |   | /  /   \    \'. \_/``".'    (_I_)  `-'`-'     / (_{;}_)|   | |   |
`---'      '---''--'     '----' '-----'      '---'    `._____.'  '(_,_) '---' '---'

https://t.me/Pixotchi
https://twitter.com/pixotchi
https://pixotchi.tech/
@audit https://blocksafu.com/
*/
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/Strings.sol";
//import "@openzeppelin/contracts-upgradeable/utils/ShortStrings.sol";


//interface IClaimer {
//    function claim(uint256 _amount, string _claimType, bytes memory _signature) external;
//}

contract Claimer is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable/*, IClaimer*/ {
    //using ShortStrings for *;
    mapping(address => uint256) public nonces;
    address public tokenAddress;
    bool public enabled;
    address public signer;
    string[] public claimType;
    using Strings for string;
    using MessageHashUtils for bytes32;
    address public vault;



    event Claim(address indexed wallet, string indexed claimType, uint256 indexed amount, uint256 nonce);

    function initialize(address _tokenAddress, address _signer, address _vault) public initializer {
        __Ownable_init(msg.sender); // Initialize the Ownable contract.
        __ReentrancyGuard_init(); // Initialize the ReentrancyGuard contract.
        __EIP712_init("Claimer", "1"); // Initialize the EIP712 contract with your domain name and version.
        vault = _vault;

        enabled = true;
        tokenAddress = _tokenAddress;
        signer = _signer;
        claimType = ["Airdrop", "Referral"];


        __EIP712_init("px-Claim", "px-EiF9no3Z");


    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function claimTypeLength() external view returns (uint256) {
        return claimType.length;
    }

    function addClaimType(string memory _claimType) external onlyOwner {
        claimType.push(_claimType);
    }

    function claim(uint256 _amount, uint256 _nonce, bytes memory _signature, string memory _claimType) external nonReentrant {
        require(enabled, "Claimer: Claiming is disabled");
        require(signer != address(0), "Claimer: Signer not set");
        require(nonces[msg.sender] == _nonce, "Claimer: Invalid nonce");
        require(_claimType.equal(string(claimType[0])) || _claimType.equal(string(claimType[1])), "Claimer: Invalid claim type");
        //verify if vault has approve this contract and amount
        require(IERC20(tokenAddress).allowance(vault, address(this)) >= _amount, "Claimer: Insufficient allowance");

        bytes32 structHash = keccak256(abi.encodePacked(msg.sender, _amount, nonces[msg.sender], _claimType));
        bytes32 digest = _hashTypedDataV4(structHash);
        require(ECDSA.recover(digest, _signature) == signer, "Claimer: Invalid signature");
//        bytes32 digest2 = _hashTypedDataV4(keccak256(abi.encode(
//            keccak256("Mail(address to,string contents)"),
//            mailTo,
//            keccak256(bytes(mailContents))
//        )));
//        address signer2 = ECDSA.recover(digest2, _signature);

        nonces[msg.sender]++;
        emit Claim(msg.sender, _claimType, _amount, _nonce);
        IERC20(tokenAddress).transferFrom(vault, msg.sender, _amount);


    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

//    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
//        return data
//        .toEthSignedMessageHash()
//        .recover(signature) == account;
//    }
}
