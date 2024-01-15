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

    // TODO: rename this
    mapping(bytes32 schemaUID => mapping(address creator => TokenData data))
        public claimTokenData;
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
            claimTokenData[schemaUID][msg.sender].token == address(0),
            "Token Already Deployed"
        );
        token = address(new SupaERC20(name, symbol, address(this)));
        claimTokenData[schemaUID][msg.sender] = TokenData({
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
            claimTokenData[attestation.schema][admin].token != address(0),
            "Token Not Deployed"
        );
        require(
            claimTokenData[attestation.schema][admin].minted == false,
            "Token Already Minted"
        );

        claimTokenData[attestation.schema][admin].minted = true;
        ISupaERC20(claimTokenData[attestation.schema][admin].token).mint(
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
