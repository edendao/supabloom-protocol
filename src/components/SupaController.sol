// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import { Attestation } from "@eas/Common.sol";
import { SupaERC20 } from "./SupaERC20.sol";

import { IEAS } from "@eas/IEAS.sol";
import { ISchemaRegistry } from "@eas/ISchemaRegistry.sol";
import { ISchemaResolver } from "@eas/resolver/ISchemaResolver.sol";
import { ISupaERC20 } from "./interfaces/ISupaERC20.sol";
import { ISupaShrine } from "./interfaces/ISupaShrine.sol";

import "forge-std/console.sol";

contract SupaController {
    error ZeroAddress();
    error RevocableAttestation();
    error AlreadyMinted();
    error TokenNotDeployed();
    error NotOperator();
    error Tokenized();
    error NotClaimed();

    uint256 internal constant OPERATOR_ROLE = 1 << 1;

    ISupaShrine public supaShrine;
    IEAS public eas;
    ISchemaRegistry public schemaRegistry;

    mapping(bytes32 schemaUID => ISupaERC20 token) public tokens;
    mapping(bytes32 claimAttestationID => address TokenClaimed)
        public claimedTokens;
    mapping(bytes32 attestationId => bool minted) public tokenized;

    constructor(IEAS _eas, address _supaShrine, address _schemaRegistry) {
        if (address(_eas) == address(0) || _schemaRegistry == address(0)){
            revert ZeroAddress();
        }

        eas = _eas;
        schemaRegistry = ISchemaRegistry(_schemaRegistry);
        supaShrine = ISupaShrine(_supaShrine);
    }


	/**
	 * @notice Register schema and deploy token
	 * @param schema The schema (string).
	 * @param name The name (string).
	 * @param symbol The symbol (string).
     * @return schemaUID schemaUID value.
	 * @return token token address value.
	 */
    function registerSchema(
        string calldata schema,
        string memory name,
        string memory symbol
    ) external returns (bytes32 schemaUID, address token) {
        schemaUID = schemaRegistry.register(schema, ISchemaResolver(address(0)), false);
        token = address(new SupaERC20{ salt: schemaUID }(name, symbol, msg.sender, address(this)));
        tokens[schemaUID] = ISupaERC20(token);
    }

	/**
	 * @notice Claims token from a claim attestation.
	 * @param claimAttestationID The claim attestation ID (bytes32).
	 * @param receiver The receiver address.
	 */
    function claim(bytes32 claimAttestationID, address receiver) external {
        Attestation memory attestation = eas.getAttestation(claimAttestationID);

        /// Checks
        if (attestation.revocable) {
            revert RevocableAttestation();
        }
        if (address(tokens[attestation.schema]) == address(0)) {
            revert TokenNotDeployed();
        }
        ISupaERC20 token = tokens[attestation.schema];
        if (!token.hasAllRoles(msg.sender, OPERATOR_ROLE)) {
            revert NotOperator();
        }
        if (tokenized[claimAttestationID]) {
            revert Tokenized();
        }

        claimedTokens[claimAttestationID] = address(token);
        tokenized[claimAttestationID] = true;
        token.mint(
            receiver,
            abi.decode(parseMsgData(attestation.data), (uint256))
        );
    }


	/**
	 * @notice Rewards token from a reward attestation.
	 * @param rewardAttestationID The reward attestation ID (bytes32).
	 * @param receiver The receiver address.
	 */
    function reward(bytes32 rewardAttestationID, address receiver) external {
        Attestation memory attestation = eas.getAttestation(
            rewardAttestationID
        );
        
        /// Checks
        if (claimedTokens[attestation.refUID] == address(0)) {
            revert NotClaimed();
        }
        address claimedToken = claimedTokens[attestation.refUID];
        // check that attestation is non-revocable
        if (attestation.revocable) {
            revert RevocableAttestation();
        }
        if (address(tokens[attestation.schema]) == address(0)) {
            revert TokenNotDeployed();
        }
        ISupaERC20 token = tokens[attestation.schema];
        if (!token.hasAllRoles(msg.sender, OPERATOR_ROLE)) {
            revert NotOperator();
        }
        if (tokenized[rewardAttestationID]) {
            revert Tokenized();
        }

        tokenized[rewardAttestationID] = true;

        uint256 rewardAmount = abi.decode(parseMsgData(attestation.data), (uint256));
        token.mint(
            receiver,
            rewardAmount
        );
        token.approve(
            address(supaShrine),
            rewardAmount
        );
        supaShrine.reward(
            claimedToken,
            address(token),
            rewardAmount
        );
    }

    function parseMsgData(bytes memory data) internal pure returns (bytes memory value_) {
        value_ = abi.encodePacked(bytes32(data));
    }
}
