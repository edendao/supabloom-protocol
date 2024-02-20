// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

interface ISupaERC20 {
    function mint(address receiver, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function currentSnapshot() external view returns (uint256 snapshotId);

    function totalSupplyAt(uint256 snapshotId) external view returns (uint256);

    function balanceOfAt(
        address user,
        uint256 snapshotId
    ) external returns (uint256);

    function incrementSnapshot() external returns (uint256 newSnapshotId);
    function hasAllRoles(address user, uint256 roles) external view returns (bool);
}
