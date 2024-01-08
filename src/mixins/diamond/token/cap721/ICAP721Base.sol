// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {
    IERC165Base
} from "@solidstate/contracts/introspection/ERC165/base/IERC165Base.sol";
import {
    IERC721Base
} from "@solidstate/contracts/token/ERC721/base/IERC721Base.sol";
import {
    IERC721Metadata
} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";

import { ICAP721Internal } from "./ICAP721Internal.sol";

interface ICAP721Base is
    ICAP721Internal,
    IERC165Base,
    IERC721Base,
    IERC721Metadata
{
    function mint(string calldata uri) external payable returns (uint256 id);

    function idRange() external view returns (uint64 minID, uint64 maxID);
}
