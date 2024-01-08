// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    LayerZeroClientBase
} from "@solidstate/layerzero/base/LayerZeroClientBase.sol";
import {
    LayerZeroClientReceiver
} from "@solidstate/layerzero/receiver/LayerZeroClientReceiver.sol";
import {
    LayerZeroClientSender
} from "@solidstate/layerzero/sender/LayerZeroClientSender.sol";
import {
    ILayerZeroEndpoint
} from "@solidstate/layerzero/interfaces/ILayerZeroEndpoint.sol";

import { AuthInternal } from "~/mixins/diamond/auth/AuthInternal.sol";

abstract contract LayerZeroClient is
    AuthInternal,
    LayerZeroClientBase,
    LayerZeroClientReceiver,
    LayerZeroClientSender
{
    function getLayerZeroEndpoint() public view returns (ILayerZeroEndpoint) {
        return ILayerZeroEndpoint(_getLayerZeroEndpoint());
    }

    function getLayerZeroConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType
    ) external view returns (bytes memory config) {
        config = getLayerZeroEndpoint().getConfig(
            version,
            chainId,
            address(this),
            configType
        );
    }

    function setLayerZeroConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external requiresAuth {
        getLayerZeroEndpoint().setConfig(version, chainId, configType, config);
    }

    function setLayerZeroReceiveVersion(uint16 version) external requiresAuth {
        getLayerZeroEndpoint().setReceiveVersion(version);
    }

    function setLayerZeroSendVersion(uint16 version) external requiresAuth {
        getLayerZeroEndpoint().setSendVersion(version);
    }

    function forceLayerZeroResumeReceive(
        uint16 srcChainId,
        bytes calldata srcAddress
    ) external requiresAuth {
        getLayerZeroEndpoint().forceResumeReceive(srcChainId, srcAddress);
    }
}
