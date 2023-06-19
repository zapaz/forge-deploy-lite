// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

// Vectorized/LibString.sol
// form https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol
// from https://gist.github.com/Vectorized/56ac210117f9baa15ac74a9ae779cd1f
library LibString {
    function replace(string memory subject, string memory search, string memory replacement)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 0x20)) { h := keccak256(search, searchLength) }
                let m := shl(3, sub(0x20, and(searchLength, 0x1f)))
                let s := mload(search)
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            let last := add(add(result, 0x20), k) // Zeroize the slot after the string.
            mstore(last, 0)
            mstore(0x40, add(last, 0x20)) // Allocate the memory.
            mstore(result, k) // Store the length.
        }
    }
}
