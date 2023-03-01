// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Library to allow push and pop method on dynamic memory array
 *
 * @notice As dynamic arrays can grow as long as elements are added it is important
 * to define a size limit of which the array cannot grow over. 
 *
 * Usage exemple:
 *
 * ```
 * using DynamicalMemoryArray for uint256;
 *
 * uint256 array_memory_pointer = DynamicalMemoryArray.create(50) // create 50 length memory array
 * DynamicalMemoryArray.push(array_memory_pointer, 100) // push 100 to the array
 * array_memory_pointer.push(100) // with attached functions
 * ```

 * @dev The array is represented as `uint256` which represents the memory slot where
 * the array is stored. This first slot represent the size of the array (as the EVM does).
 * Operation on arrays are performed by specifying the memory pointer of the array.
 *
 * When an array is created the current free memory pointer is offset to the maximum limit of the
 * array (or the DEFAULT_SIZE), in order to keep the memory safe while push element into the array.
 *
 * The library allows unsafe operation to arbitrarily write on memory with method such as
 * `pushUnchecked`, `popUnchecked`  and `pushAt`. Indeed you can create an array by calling `pushAt`.
 */
library DynamicalMemoryArray {
    /// @dev a limit in memory is set to not consume to much gas
    error TooFarInMemory();
    error MaxArraySizeReached();
    error PopOnEmptyArray();

    /// @dev Maximum number of elements by default
    uint256 internal constant DEFAULT_SIZE = 256;

    /**
     * @notice Create an array with the `DEFAULT_SIZE`
     * @dev The free memory pointer is offset by the `DEFAULT_SIZE`
     *
     * @return mem_ptr memory pointer where operation are performed
     */
    function create() internal pure returns (uint256 mem_ptr) {
        return _create(DEFAULT_SIZE);
    }

    /**
     * @notice Create an array with a custom
     * @dev The free memory pointer is offset by the `max_size`, assuming
     * the array will not grow over this limit
     *
     * @param max_size limit on which the array stop growing
     * @return mem_ptr memory pointer where operation are performed
     */
    function create(uint256 max_size) internal pure returns (uint256 mem_ptr) {
        return _create(max_size);
    }

    /**
     * @notice Push an element to a dynamic memory array
     * @dev the function check if (1) the next memory slot is empty (avoid
     * erasing memory) and if (2) if the next memory slot is not after or
     * on the free memory pointer (avoid erase array data with new data on memory)
     *
     * @param mem_ptr array memory pointer to push on
     * @param value element to push
     * */
    function push(uint256 mem_ptr, uint256 value) internal pure {
        // check if new memory slot is empty
        uint256 next_mslot;
        uint256 current_ptr;
        assembly {
            next_mslot := mload(add(mem_ptr, mul(32, add(mload(mem_ptr), 1))))
            current_ptr := mload(0x40)
        }
        if (next_mslot != 0 || next_mslot >= current_ptr)
            revert MaxArraySizeReached();
        _push(mem_ptr, value);
    }

    /**
     * @notice Push an element to an arbitrarily dynamic memory array
     * @dev this function check only if the next memory slot is empty
     * This allow to write in memory after the free memory pointer. And
     * can be useful to create array linked by a small key (max: `uint16`)
     *
     * @param mem_ptr array memory pointer to push on
     * @param value element to push
     * */
    function pushAt(uint256 mem_ptr, uint256 value) internal pure {
        uint256 next_mslot;
        assembly {
            next_mslot := mload(add(mem_ptr, mul(32, add(mload(mem_ptr), 1))))
        }
        if (next_mslot != 0) revert MaxArraySizeReached();
        _push(mem_ptr, value);
    }

    /**
     * @notice Unsafe method to push element into an array
     * @dev CAUTION: this function do not perform any check, the memory
     * can be erased and produce inexpected result
     *
     * @param mem_ptr array memory pointer to push on
     * @param value element to push
     * */
    function pushUnchecked(uint256 mem_ptr, uint256 value) internal pure {
        _push(mem_ptr, value);
    }

    /**
     * @notice Remove the last element from an array
     * @dev the function check if the array is not empty
     *
     * @param mem_ptr array memory pointer to pop
=     * */
    function pop(uint256 mem_ptr) internal pure {
        // check if size is not zero
        uint256 size;
        assembly {
            size := mload(mem_ptr)
        }
        if (size == 0) revert PopOnEmptyArray();
        _pop(mem_ptr);
    }

    /**
     * @notice Unsafe method to pop an element from an array
     * @dev CAUTION: this function do not perform any check, the memory
     * can be erased and produce inexpected result
     *
     * @param mem_ptr array memory pointer to push on
     * */
    function popUnchecked(uint256 mem_ptr) internal pure {
        _pop(mem_ptr);
    }

    /**
     * @notice Return the array corresponding to an array memory pointer
     *
     * @param mem_ptr array memory pointer to transform into memory array
     * @return _ a memory array
     * */
    function toArray(uint256 mem_ptr) internal pure returns (uint256[] memory) {
        uint256 size;
        uint256 current_ptr;
        assembly {
            size := mload(mem_ptr)
            current_ptr := mload(0x40)
            mstore(0x40, mem_ptr)
        }
        uint256[] memory createdArray = new uint256[](0);
        assembly {
            mstore(mem_ptr, size)
            mstore(0x40, current_ptr)
        }
        return createdArray;
    }

    /**
     * @notice Read the length of an array
     *
     * @param mem_ptr array memory pointer to read
     * @return size number of elements
     * */
    function length(uint256 mem_ptr) internal pure returns (uint256 size) {
        assembly {
            size := mload(mem_ptr)
        }
    }

    /**
     * @notice Read a value in the array at an index
     * @dev CAUTION: the size of the array is not checked,
     * will return zero if out of bound.
     *
     * @param mem_ptr array memory pointer to read
     * @param index index to read
     * @return ret value at index
     * */
    function at(uint256 mem_ptr, uint256 index)
        internal
        pure
        returns (uint256 ret)
    {
        assembly {
            ret := mload(add(mem_ptr, mul(32, add(index, 1))))
        }
    }

    /*////////////////////////////////////////////////////////////////////////////////////////////////
                                            PRIVATE METHODS
    ////////////////////////////////////////////////////////////////////////////////////////////////*/
    function _push(uint256 mem_ptr, uint256 value) private pure {
        assembly {
            let size := add(mload(mem_ptr), 1)
            mstore(mem_ptr, size)
            mstore(add(mem_ptr, mul(size, 32)), value)
        }
    }

    function _pop(uint256 mem_ptr) private pure {
        assembly {
            let size := mload(mem_ptr)
            mstore(add(mem_ptr, mul(size, 32)), 0)
            mstore(mem_ptr, sub(size, 1))
        }
    }

    function _create(uint256 max_size) private pure returns (uint256 mem_ptr) {
        uint256 new_ptr;

        assembly {
            max_size := add(max_size, 1)
            mem_ptr := mload(0x40)
            new_ptr := add(mem_ptr, mul(max_size, 32))
            mstore(0x40, add(mem_ptr, mul(max_size, 32)))
        }

        if (new_ptr > 0xFFFF) revert TooFarInMemory();
    }
}
