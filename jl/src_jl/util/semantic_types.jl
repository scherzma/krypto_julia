@enum Semantic GCM XEX

function from_string(s::String)::Semantic
    return s == "gcm" ? GCM : XEX
end