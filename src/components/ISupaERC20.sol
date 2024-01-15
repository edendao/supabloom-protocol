// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ISupaERC20 {
    function mint(address receiver, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}
