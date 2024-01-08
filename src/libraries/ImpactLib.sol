// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title ImpactLib
/// @notice A library for storing and validating verifiable values, a cousin of
///         verifiable credential meant to describe an *impact event* rather than an *agent*.
library ImpactLib {
    error ImpactLib__InvalidSigner();
    error ImpactLib__InvalidTimestamps();
    error ImpactLib__InvalidURI();

    struct Attestation {
        uint64 amount;
        uint32 startAt;
        uint32 endAt;
        address signer;
        string uri;
    }

    function exists(Attestation storage v) internal view returns (bool) {
        return v.signer != address(0);
    }

    function isRevoked(Attestation storage v) internal view returns (bool) {
        return exists(v) && (v.startAt == 0 || v.endAt == 0);
    }

    function revoke(Attestation storage v) internal {
        v.startAt = 0;
        v.endAt = 0;
    }

    function validate(Attestation memory v) internal pure {
        if (v.signer == address(0)) {
            revert ImpactLib__InvalidSigner();
        }
        if (v.startAt == 0 || v.endAt == 0 || v.startAt > v.endAt) {
            revert ImpactLib__InvalidTimestamps();
        }
        if (bytes(v.uri).length == 0) {
            revert ImpactLib__InvalidURI();
        }
    }

    bytes32 internal constant VALUE_TYPEHASH =
        keccak256(
            // solhint-disable-next-line max-line-length
            "ImpactLib.Attestation(uint64 amount,uint32 startAt,uint32 endAt,address signer,string uri)"
        );

    function hashAttestation(
        ImpactLib.Attestation calldata v
    ) internal pure returns (bytes32 dataHash) {
        validate(v);

        dataHash = keccak256(
            abi.encode(
                VALUE_TYPEHASH,
                v.amount,
                v.startAt,
                v.endAt,
                v.signer,
                keccak256(bytes(v.uri))
            )
        );
    }
}
