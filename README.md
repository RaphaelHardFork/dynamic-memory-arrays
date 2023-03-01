# Dynamic memory arrays

_Library to use `pop` and `push` method with memory arrays_

## Usage

```
forge install ...
```

---

## Docs

_generated with `forge doc`_

### DynamicalMemoryArray.sol

As dynamic arrays can grow as long as elements are added it is important
to define a size limit of which the array cannot grow over.
Usage exemple:

```
using DynamicalMemoryArray for uint256;
uint256 array_memory_pointer = DynamicalMemoryArray.create(50) // create 50 length memory array
DynamicalMemoryArray.push(array_memory_pointer, 100) // push 100 to the array
array_memory_pointer.push(100) // with attached functions
```

_The array is represented as `uint256` which represents the memory slot where
the array is stored. This first slot represent the size of the array (as the EVM does).
Operation on arrays are performed by specifying the memory pointer of the array.
When an array is created the current free memory pointer is offset to the maximum limit of the
array (or the DEFAULT_SIZE), in order to keep the memory safe while push element into the array.
The library allows unsafe operation to arbitrarily write on memory with method such as
`pushUnchecked`, `popUnchecked` and `pushAt`. Indeed you can create an array by calling `pushAt`._

## State Variables

### DEFAULT_SIZE

_Maximum number of elements by default_

```solidity
uint256 internal constant DEFAULT_SIZE = 256;
```

## Functions

### create

Create an array with the `DEFAULT_SIZE`

_The free memory pointer is offset by the `DEFAULT_SIZE`_

```solidity
function create() internal pure returns (uint256 mem_ptr);
```

**Returns**

| Name      | Type      | Description                                  |
| --------- | --------- | -------------------------------------------- |
| `mem_ptr` | `uint256` | memory pointer where operation are performed |

### create

Create an array with a custom

_The free memory pointer is offset by the `max_size`, assuming
the array will not grow over this limit_

```solidity
function create(uint256 max_size) internal pure returns (uint256 mem_ptr);
```

**Parameters**

| Name       | Type      | Description                           |
| ---------- | --------- | ------------------------------------- |
| `max_size` | `uint256` | limit on which the array stop growing |

**Returns**

| Name      | Type      | Description                                  |
| --------- | --------- | -------------------------------------------- |
| `mem_ptr` | `uint256` | memory pointer where operation are performed |

### push

Push an element to a dynamic memory array

_the function check if (1) the next memory slot is empty (avoid
erasing memory) and if (2) if the next memory slot is not after or
on the free memory pointer (avoid erase array data with new data on memory)_

```solidity
function push(uint256 mem_ptr, uint256 value) internal pure;
```

**Parameters**

| Name      | Type      | Description                     |
| --------- | --------- | ------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to push on |
| `value`   | `uint256` | element to push                 |

### pushAt

Push an element to an arbitrarily dynamic memory array

_this function check only if the next memory slot is empty
This allow to write in memory after the free memory pointer. And
can be useful to create array linked by a small key (max: `uint16`)_

```solidity
function pushAt(uint256 mem_ptr, uint256 value) internal pure;
```

**Parameters**

| Name      | Type      | Description                     |
| --------- | --------- | ------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to push on |
| `value`   | `uint256` | element to push                 |

### pushUnchecked

Unsafe method to push element into an array

_CAUTION: this function do not perform any check, the memory
can be erased and produce inexpected result_

```solidity
function pushUnchecked(uint256 mem_ptr, uint256 value) internal pure;
```

**Parameters**

| Name      | Type      | Description                     |
| --------- | --------- | ------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to push on |
| `value`   | `uint256` | element to push                 |

### pop

Remove the last element from an array

_the function check if the array is not empty_

```solidity
function pop(uint256 mem_ptr) internal pure;
```

**Parameters**

| Name      | Type      | Description                      |
| --------- | --------- | -------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to pop = \* |

### popUnchecked

Unsafe method to pop an element from an array

_CAUTION: this function do not perform any check, the memory
can be erased and produce inexpected result_

```solidity
function popUnchecked(uint256 mem_ptr) internal pure;
```

**Parameters**

| Name      | Type      | Description                     |
| --------- | --------- | ------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to push on |

### toArray

Return the array corresponding to an array memory pointer

```solidity
function toArray(uint256 mem_ptr) internal pure returns (uint256[] memory);
```

**Parameters**

| Name      | Type      | Description                                         |
| --------- | --------- | --------------------------------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to transform into memory array |

**Returns**

| Name     | Type        | Description       |
| -------- | ----------- | ----------------- |
| `<none>` | `uint256[]` | \_ a memory array |

### length

Read the length of an array

```solidity
function length(uint256 mem_ptr) internal pure returns (uint256 size);
```

**Parameters**

| Name      | Type      | Description                  |
| --------- | --------- | ---------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to read |

**Returns**

| Name   | Type      | Description        |
| ------ | --------- | ------------------ |
| `size` | `uint256` | number of elements |

### at

Read a value in the array at an index

_CAUTION: the size of the array is not checked,
will return zero if out of bound._

```solidity
function at(uint256 mem_ptr, uint256 index) internal pure returns (uint256 ret);
```

**Parameters**

| Name      | Type      | Description                  |
| --------- | --------- | ---------------------------- |
| `mem_ptr` | `uint256` | array memory pointer to read |
| `index`   | `uint256` | index to read                |

**Returns**

| Name  | Type      | Description    |
| ----- | --------- | -------------- |
| `ret` | `uint256` | value at index |

### \_push

```solidity
function _push(uint256 mem_ptr, uint256 value) private pure;
```

### \_pop

```solidity
function _pop(uint256 mem_ptr) private pure;
```

### \_create

```solidity
function _create(uint256 max_size) private pure returns (uint256 mem_ptr);
```

## Errors

### TooFarInMemory

_a limit in memory is set to not consume to much gas_

```solidity
error TooFarInMemory();
```

### MaxArraySizeReached

```solidity
error MaxArraySizeReached();
```

### PopOnEmptyArray

```solidity
error PopOnEmptyArray();
```
