// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    IERC721BaseInternal
} from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";

interface ICAP721Internal is IERC721BaseInternal {
    event MetadataUpdate(uint256 indexed id);
    event URI(string value, uint256 indexed id);
}
