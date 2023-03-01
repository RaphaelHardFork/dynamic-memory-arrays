// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {DynamicalMemoryArray} from "contracts/DynamicalMemoryArray.sol";

contract DynamicalMemoryArray_test is Test {
    using DynamicalMemoryArray for uint256;

    function test_create_CreateDefaultArray() public {
        uint256 array_key1 = DynamicalMemoryArray.create();
        uint256 array_key2 = DynamicalMemoryArray.create();

        assertEq(
            array_key2 - array_key1,
            (1 + 256) * 32,
            "Array1 is 256 (+1) length"
        );
    }

    function test_create_CreateSizedArray() public {
        uint256 array_key1 = DynamicalMemoryArray.create(10);
        uint256 array_key2 = DynamicalMemoryArray.create(50);
        uint256 array_key3 = DynamicalMemoryArray.create();

        assertEq(
            array_key2 - array_key1,
            (1 + 10) * 32,
            "Array1 is 10 (+1) length"
        );
        assertEq(
            array_key3 - array_key2,
            (1 + 50) * 32,
            "Array2 is 50 (+1) length"
        );
    }

    function test_create_CannotGoTooFarInMemory() public {
        vm.expectRevert(DynamicalMemoryArray.TooFarInMemory.selector);
        DynamicalMemoryArray.create(2044); // maximal size

        // or 7 x default size
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        DynamicalMemoryArray.create();
        vm.expectRevert(DynamicalMemoryArray.TooFarInMemory.selector);
        DynamicalMemoryArray.create();
    }

    function test_pushAt_UseAsMicroMapping() public {
        uint256 key1 = 0x0104;
        uint256 key2 = 0xFa07;
        uint256 key3 = 0xe302;
        uint256 key4 = 0x05a3;

        key1.pushAt(0xf00);
        key1.pushAt(0xf00);
        key2.pushAt(0xf00);
        key2.pushAt(0xf00);
        key4.pushAt(0xf00);
        key4.pushAt(0xf00);
        key1.pushAt(0xf00);
        key3.pushAt(0xf00);
        key3.pushAt(0xf00);

        assertEq(key1.length(), 3);
        assertEq(key2.length(), 2);
        assertEq(key3.length(), 2);
        assertEq(key4.length(), 2);
    }

    function test_push_AddElementToArray() public {
        uint256 array_key = DynamicalMemoryArray.create(10);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);

        assertEq(array_key.length(), 4);
    }

    function test_push_LargeNumberOfElement() public {
        uint256 array_key = DynamicalMemoryArray.create(10);
        for (uint256 i; i < 2000; i++) {
            array_key.push(0xb0ca8e5);
        }
        assertEq(array_key.length(), 2000);
    }

    function test_push_VeryFarInMemory() public {
        uint256 array_key = 0xFFaa;

        for (uint256 i; i < 10000; i++) {
            array_key.pushAt(0xb0ca8e5);
        }

        assertEq(array_key.length(), 10000);
    }

    function test_push_CannotEraseMemory() public {
        uint256 array_key = DynamicalMemoryArray.create(4);
        uint256 fill_memory = DynamicalMemoryArray.create(1);
        fill_memory.push(0xf177);

        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        vm.expectRevert(DynamicalMemoryArray.MaxArraySizeReached.selector);
        array_key.push(0xb0ca8e5);
    }

    function test_push_CannotWriteOnFreeMemoryPointer() public {
        uint256 array_key = DynamicalMemoryArray.create(4);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        vm.expectRevert(DynamicalMemoryArray.MaxArraySizeReached.selector);
        array_key.push(0xb0ca8e5);
    }

    function test_pushUnchecked_CanEraseMemory() public {
        uint256 array_key = DynamicalMemoryArray.create(4);
        uint256 fill_memory = DynamicalMemoryArray.create(1);
        fill_memory.push(0xf177);

        assertEq(fill_memory.at(0), 0xf177);

        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.pushUnchecked(5); // erase fill_memory size
        array_key.pushUnchecked(0xe4a5ed); // erase fill_memory[0]

        assertEq(fill_memory.length(), 5);
        assertEq(fill_memory.at(0), 0xe4a5ed);
    }

    function test_pop_PopElements() public {
        uint256 array_key = DynamicalMemoryArray.create(4);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);

        assertEq(array_key.length(), 4);

        array_key.pop();
        array_key.pop();

        assertEq(array_key.length(), 2);
    }

    function test_pop_CannotPopEmptyArray() public {
        uint256 array_key = DynamicalMemoryArray.create(4);
        vm.expectRevert(DynamicalMemoryArray.PopOnEmptyArray.selector);
        array_key.pop();
    }

    function test_popUnchecked_EraseMemory() public {
        uint256 fill_memory = DynamicalMemoryArray.create(4);
        uint256 array_key = DynamicalMemoryArray.create(1);

        fill_memory.push(0xb0ca8e5);
        fill_memory.push(0xb0ca8e5);
        fill_memory.push(0xb0ca8e5);
        fill_memory.push(0xb0ca8e5);

        array_key.popUnchecked();
        array_key.popUnchecked();

        assertEq(fill_memory.at(2), 0xb0ca8e5);
        assertEq(fill_memory.at(3), 0);
    }

    function test_toArray_TransformIntoArray() public {
        uint256 array_key = DynamicalMemoryArray.create(5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);
        array_key.push(0xb0ca8e5);

        assertEq(array_key.length(), 4);
        uint256[] memory array = array_key.toArray();
        assertEq(array.length, 4);
    }

    function test_toArray_TransformArbitraryArray() public {
        // create array somewhere in memory
        uint256 key = 0xa0aa;

        key.pushAt(555);
        key.pushAt(555);
        key.pushAt(555);
        key.pushAt(555);
        key.pushAt(555);

        assertEq(key.length(), 5);
        uint256[] memory a = key.toArray();

        assertEq(a.length, 5);
        assertEq(a[0], 555);
        assertEq(a[1], 555);
        assertEq(a[2], 555);
        assertEq(a[3], 555);
        assertEq(a[4], 555);
    }
}
