//
// Created by user on 28/11/24.
//

#ifndef LOOKUP_H
#define LOOKUP_H


constexpr std::array<uint8_t, 256> bitReverseTable = []{
    std::array<uint8_t, 256> table = {};
    for (uint16_t i = 0; i < 256; ++i) {
        uint8_t v = i;
        v = ((v & 0xF0) >> 4) | ((v & 0x0F) << 4);
        v = ((v & 0xCC) >> 2) | ((v & 0x33) << 2);
        v = ((v & 0xAA) >> 1) | ((v & 0x55) << 1);
        table[i] = v;
    }
    return table;
}();



#endif //LOOKUP_H
