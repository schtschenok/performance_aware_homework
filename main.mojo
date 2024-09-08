import os
import sys
from pathlib import Path
from collections import Dict, InlineList

alias Byte = UInt8
alias Bytes = List[Byte]
alias MAX_INSTRUCTION_SIZE = 6


fn main() raises:
    var file: Path = Path("")

    file = Path("data/listing_0038_many_register_mov")

    # var paths = sys.argv()
    # if len(paths) == 2:
    #     file = Path(paths[1])
    # else:
    #     print("Please supply file name as an argument")
    #     sys.exit(1)

    with open(file, "r") as f:
        var current_byte: Byte = 0
        var instruction: Bytes = Bytes()
        instruction.reserve(MAX_INSTRUCTION_SIZE + 1)
        var file_size = f.seek(0, os.SEEK_END)
        _ = f.seek(0, os.SEEK_SET)
        # print("File size: " + str(file_size))
        print("bits 16\n")
        for _ in range(file_size):
            current_byte = f.read_bytes(1)[0]
            instruction.append(current_byte)
            if is_there_enough_bytes(instruction):
                var result: Tuple[Bool, String] = process_instruction(
                    instruction
                )
                if result[0]:
                    print(result[1])
                else:
                    # print("Failed to decode: " + result[1])
                    continue
                instruction.clear()
            else:
                continue
        # print("END!")


fn process_instruction(instruction: Bytes) -> Tuple[Bool, String]:
    var result: String

    var W: Bool = False
    var D: Bool = False

    # Single-byte case
    if len(instruction) == 1:
        result = "Unsupported single-byte instruction"
        return False, result

    # MOV case
    if BitmaskedByte(0b10001000, 0b11111100) == instruction[0]:
        var operation: String = "mov"
        var source_reg: String
        var dest_reg: String

        if BitmaskedByte(0b00000010, 0b00000010) == instruction[0]:
            D = True
            return False, str("MOV with D == False, not supported")

        if BitmaskedByte(0b00000001, 0b00000001) == instruction[0]:
            W = True

        if BitmaskedByte(0b11000000, 0b11000000) != instruction[1]:
            return False, str("MOV with some MOD other than 11, not supported")

        source_reg = get_reg(instruction[1] >> 3, W)
        dest_reg = get_reg(instruction[1], W)

        result = operation + " " + dest_reg + ", " + source_reg
        return True, result

    return False, str("Unsupported instruction")


fn get_instruction_size(first_byte: Byte, second_byte: Byte) raises -> UInt8:
    return 2  # Placeholder


fn is_there_enough_bytes(bytes: Bytes) raises -> Bool:
    var single_byte_instructions: InlineList[BitmaskedByte, 4] = InlineList[
        BitmaskedByte, 4
    ](
        BitmaskedByte(0b01010000, 0b11111000),
        BitmaskedByte(0b00000110, 0b11100111),
        BitmaskedByte(0b01011000, 0b11111000),
        BitmaskedByte(0b00000111, 0b11100111),  # And there's many more!
    )  # Should be a global variable? But global variables don't work in compiled (not JIT-ed) executables (yet)

    # print(
    #     "Is There Enough Bytes called with number of bytes: " + str(len(bytes))
    # )
    if len(bytes) == 0:
        raise ("This function shouldn't ever be called with empty list")
    elif len(bytes) == 1:
        for i in range(len(single_byte_instructions)):
            if single_byte_instructions[i] == bytes[0]:
                # print("There is enough bytes, " + str(len(bytes)) + "!")
                return True
        else:
            # print("There is not enough bytes, " + str(len(bytes)) + " :(")
            return False
    elif 1 < len(bytes) < MAX_INSTRUCTION_SIZE:
        var instruction_size: UInt8 = get_instruction_size(bytes[0], bytes[1])
        if instruction_size == len(bytes):
            # print("There is enough bytes, " + str(len(bytes)) + "!")
            return True
        else:
            # print("There is not enough bytes, " + str(len(bytes)) + " :(")
            return False
    else:
        raise ("Invalid instruction - extra bytes")


struct BitmaskedByte(KeyElement):
    var byte: UInt8
    var bitmask: UInt8

    @always_inline
    fn __init__(inout self, byte: UInt8, bitmask: UInt8):
        self.byte = byte
        self.bitmask = bitmask

    @always_inline
    fn __eq__(self, other: UInt8) -> Bool:
        return self.byte == other & self.bitmask

    @always_inline
    fn __ne__(self, other: UInt8) -> Bool:
        return not (self == other)

    @always_inline
    fn __copyinit__(inout self, existing: Self):
        self.byte = existing.byte
        self.bitmask = existing.bitmask

    @always_inline
    fn __moveinit__(inout self, owned existing: Self):
        self.byte = existing.byte
        self.bitmask = existing.bitmask

    @always_inline
    fn __hash__(self) -> Int:
        return hash((self.byte << 8) | self.bitmask)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.byte == other.byte and self.bitmask == other.bitmask

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)


# Should this be a data structure instead? Probably yep.
fn get_reg(input: UInt8, W: Bool) -> String:
    var three_bits = input & 0b111
    var result: String = ""

    if three_bits == 0b000:
        if W:
            result = "ax"
        else:
            result = "al"
    elif three_bits == 0b001:
        if W:
            result = "cx"
        else:
            result = "cl"
    elif three_bits == 0b010:
        if W:
            result = "dx"
        else:
            result = "dl"
    elif three_bits == 0b011:
        if W:
            result = "bx"
        else:
            result = "bl"
    elif three_bits == 0b100:
        if W:
            result = "sp"
        else:
            result = "ah"
    elif three_bits == 0b101:
        if W:
            result = "bp"
        else:
            result = "ch"
    elif three_bits == 0b110:
        if W:
            result = "si"
        else:
            result = "dh"
    elif three_bits == 0b111:
        if W:
            result = "di"
        else:
            result = "bh"
    return result
