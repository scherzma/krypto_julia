

module Conversions
using Nemo
using Base64

function base64_to_Nemo(base64::String, semantic::String)

    result::ZZRingElem = 0
    a_array = base64decode(base64)

    if semantic == "xex"
        reverse!(a_array)
        for byte in a_array
            result = result << 8  # Shift left by 8 bits
            result = result | ZZ(byte)  # OR with current byte
        end
    elseif semantic == "gcm"
        for byte in a_array
            result = result << 8  # Shift left by 8 bits
            result = result | ZZ(byte)  # OR with current byte
        end
    end

    return result
end

end