// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

// solhint-disable avoid-low-level-calls
library CallLib {
    error CallLib__CallFailed();
    error CallLib__CallWithValueFailed();
    error CallLib__InsufficientBalance();
    error CallLib__NotContract();
    error CallLib__SendValueFailed();

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size != 0;
    }

    function sendValue(address payable account, uint256 value) internal {
        (bool success,) = account.call{value: value}("");
        if (!success) revert CallLib__SendValueFailed();
    }

    function staticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return _staticCall(target, data, CallLib__CallFailed.selector);
    }

    function staticCall(address target, bytes memory data, bytes4 errorSelector) internal view returns (bytes memory) {
        return _staticCall(target, data, errorSelector);
    }

    function delegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return _delegateCall(target, data, CallLib__CallFailed.selector);
    }

    function delegateCall(address target, bytes memory data, bytes4 errorSelector) internal returns (bytes memory) {
        return _delegateCall(target, data, errorSelector);
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, CallLib__CallFailed.selector);
    }

    function functionCall(address target, bytes memory data, bytes4 errorSelector) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorSelector);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, CallLib__CallWithValueFailed.selector);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, bytes4 errorSelector)
        internal
        returns (bytes memory)
    {
        if (value > address(this).balance) {
            revert CallLib__InsufficientBalance();
        }
        return _functionCallWithValue(target, data, value, errorSelector);
    }

    function _staticCall(address target, bytes memory data, bytes4 errorSelector)
        internal
        view
        returns (bytes memory)
    {
        if (!isContract(target)) revert CallLib__NotContract();

        (bool success, bytes memory result) = target.staticcall(data);

        if (success) {
            return result;
        } else if (result.length != 0) {
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            assembly {
                mstore(0, errorSelector)
                revert(0, 4)
            }
        }
    }

    function _delegateCall(address target, bytes memory data, bytes4 errorSelector) internal returns (bytes memory) {
        (bool success, bytes memory result) = target.delegatecall(data);

        if (success) {
            return result;
        } else if (result.length != 0) {
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            assembly {
                mstore(0, errorSelector)
                revert(0, 4)
            }
        }
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 value, bytes4 errorSelector)
        private
        returns (bytes memory)
    {
        (bool success, bytes memory result) = target.call{value: value}(data);

        if (success) {
            return result;
        } else if (result.length != 0) {
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            assembly {
                mstore(0, errorSelector)
                revert(0, 4)
            }
        }
    }
}
