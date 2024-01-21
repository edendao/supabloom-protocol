pragma solidity 0.8.21;

import { ISupaERC20 } from "./ISupaERC20.sol";
import { SupaERC20 } from "./SupaERC20.sol";
import { IEAS } from "@eas/IEAS.sol";
import { Attestation } from "@eas/Common.sol";

contract SupaController {
    error InvalidEAS();

    struct TokenData {
        string name;
        string symbol;
        address token;
        bool minted;
    }

    mapping(bytes32 schemaUID => mapping(address creator => TokenData data))
        public tokenData;
    mapping(bytes32 claimAttestationID => address TokenClaimed)
        public claimsToTokens;
    // The address of the global EAS contract.
    IEAS public immutable eas;
    mapping(address approved => address admin) public operators;

    constructor(IEAS _eas) {
        if (address(_eas) == address(0)) {
            revert InvalidEAS();
        }

        eas = _eas;
    }

    function registerSchema(
        bytes32 schemaUID,
        string memory name,
        string memory symbol
    ) external returns (address token) {
        // Check if the token is already deployed by the msg.sender
        require(
            tokenData[schemaUID][msg.sender].token == address(0),
            "Token Already Deployed"
        );
        token = address(new SupaERC20(name, symbol, address(this)));
        tokenData[schemaUID][msg.sender] = TokenData({
            name: name,
            symbol: symbol,
            token: token,
            minted: false
        });
        operators[msg.sender] = msg.sender;
    }

    function claim(bytes32 claimAttestationID, address receiver) external {
        Attestation memory attestation = eas.getAttestation(claimAttestationID);

        // check that attestation is non-revocable
        require(
            attestation.revocable == false,
            "Only non-revocable attestations"
        );

        address admin = operators[msg.sender];
        require(
            tokenData[attestation.schema][admin].token != address(0),
            "Token Not Deployed"
        );
        require(
            tokenData[attestation.schema][admin].minted == false,
            "Token Already Minted"
        );

        tokenData[attestation.schema][admin].minted = true;
        claimsToTokens[claimAttestationID] = tokenData[attestation.schema][
            admin
        ].token;
        ISupaERC20(tokenData[attestation.schema][admin].token).mint(
            receiver,
            abi.decode(attestation.data, (uint256))
        );
    }

    function addOperators(address[] calldata _operators) external {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = msg.sender;
        }
    }
}
