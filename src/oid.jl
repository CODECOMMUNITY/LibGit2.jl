export Oid, hex, oid, raw, iszero

type Sha1
    sha1::String
    
    Sha1(s::String) = begin
        if length(s) != api.OID_HEXSZ
            throw(ArgumentError("invalid sha1 string length"))
        end
        return new(s)
    end
end

macro sha1_str(s)
    Sha1(s)
end

type Oid
    oid::Array{Uint8,1}

    Oid(b::Array{Uint8, 1}) = begin
        if length(b) != api.OID_RAWSZ
            throw(ArgumentError("invalid raw buffer size"))
        end
        return new(b)
    end
end

Oid() = Oid(zeros(Uint8, api.OID_RAWSZ))

Oid(h::String) = begin
    if length(h) != api.OID_HEXSZ
        throw(ArgumentError("invalid hex size"))
    end
    bytes = hex2bytes(bytestring(h))
    return Oid(bytes)
end

Oid(ptr::Ptr{Uint8}) = begin
    @assert ptr != C_NULL
    oid = Array(Uint8, api.OID_RAWSZ)
    unsafe_copy!(pointer(oid), ptr, api.OID_RAWSZ)
    return Oid(oid)
end

Base.string(oid::Oid) = hex(oid)
Base.show(io::IO, oid::Oid) = print(io, "Oid($(string(oid)))")

Base.hash(oid::Oid) = hash(hex(oid))

Base.cmp(oid1::Oid, oid2::Oid) = begin
    git_cmp = ccall((:git_oid_cmp, api.libgit2),
                    Cint,
                    (Ptr{Uint8}, Ptr{Uint8}),
                    oid1.oid, oid2.oid)
    return git_cmp
end

Base.isequal(oid1::Oid, oid2::Oid) = cmp(oid1, oid2) == 0
Base.isless(oid1::Oid, oid2::Oid)  = cmp(oid1, oid2) < 0

Base.copy(oid::Oid) = Oid(copy(oid.oid))

oid(id::Oid)  = id
hex(oid::Oid) = bytes2hex(oid.oid)
raw(oid::Oid) = copy(oid.oid)

iszero(oid::Oid) = begin
    for i in api.OID_RAWSZ
        if oid.oid[i] != zero(Uint8)
            return false
        end
    end
    return true
end
