export GitBlob, git_otype, is_binary, raw_content

type GitBlob <: GitObject
    ptr::Ptr{Void}

    function GitBlob(ptr::Ptr{Void})
        b = new(ptr)
        finalizer(b, free!)
        return b
    end
end

git_otype(::Type{GitBlob}) = api.OBJ_BLOB

Base.sizeof(b::GitBlob) = begin
    @assert b.ptr != C_NULL
    return api.git_blob_rawsize(b.ptr)::Int64
end

function is_binary(b::GitBlob)
    @assert b.ptr != C_NULL
    api.git_blob_is_binary(b.ptr) > 0 ? true : false
end

function raw_content(b::GitBlob)
    @assert b.ptr != C_NULL
    ptr = api.git_blob_rawcontent(b.ptr)
    if ptr == C_NULL
        return nothing
    end
    return bytestring(convert(Ptr{Cchar}, ptr))
    #n = div(sizeof(b), sizeof(Cchar))
    #buf = Array(Cchar, n)
    #for i in 1:n
    #    buf[i] = unsafe_load(ptr, i)::Cchar
    #end
    #return buf
end
