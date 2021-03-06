export LibGitError

baremodule GitErrorConst
    import ..cint

    const GIT_OK          = cint(0)
    const ERROR           = cint(-01)
    const ENOTFOUND       = cint(-03)
    const EEXISTS         = cint(-04)
    const EAMBIGUOUS      = cint(-05)
    const EBUFS           = cint(-06)
    const EUSER           = cint(-07)
    const EBAREREPO       = cint(-08)
    const EUNBORNBRANCH   = cint(-09)
    const EUNMERGED       = cint(-10)
    const ENONFASTFORWARD = cint(-11)
    const EINVALIDSPEC    = cint(-12)
    const EMERGECONFLICT  = cint(-13)
    const ELOCKED         = cint(-14)
    const PASSTHROUGH     = cint(-30)
    const ITEROVER        = cint(-31)
end

const git_error_code = Dict{Int,Symbol}(
     00 => :OK,             # no error
    -01 => :Error,          # generic error
    -03 => :NotFound,       # requested object could not be found
    -04 => :Exists,         # object exits preventing op
    -05 => :Ambiguous,      # more than one object matches
    -06 => :Bufs,           # output buffer too small to hold data
    -07 => :User,           # user callback generated error
    -08 => :BareRepo,       # operation not allowed on bare repo
    -09 => :UnbornBranch,   # HEAD refers to branch with 0 commits
    -10 => :Unmerged,       # merge in progress prevented op
    -11 => :NonFastForward, # ref not fast-forwardable
    -12 => :InvalidSpec,    # name / ref not in valid format
    -13 => :MergeConflict,  # merge conflict prevented op
    -14 => :Locked,         # lock file prevented op
    -15 => :Modified,       # ref value does not match expected
    -31 => :Iterover        # signals end of iteration
)

const git_error_class = Dict{Int,Symbol}(
     0 => :None,
     1 => :NoMemory,
     2 => :OS,
     3 => :Invalid,
     4 => :Ref,
     5 => :Zlib,
     6 => :Repo,
     7 => :Config,
     8 => :Regex,
     9 => :Odb,
    10 => :Index,
    11 => :Object,
    12 => :Net,
    13 => :Tag,
    14 => :Tree,
    15 => :Indexer,
    16 => :SSL,
    17 => :Submodule,
    18 => :Thread,
    19 => :Stash,
    20 => :Checkout,
    21 => :FetchHead,
    22 => :Merge,
    23 => :SSH,
    24 => :Filter,
    25 => :Revert,
    26 => :Callback,
    27 => :CherryPick
)

immutable ErrorStruct
    message::Ptr{UInt8}
    class::Cint
end

immutable LibGitError{Class, Code}
    msg::UTF8String
end

function last_error()
    err = ccall((:giterr_last, libgit2), Ptr{ErrorStruct}, ())
    err_obj   = unsafe_load(err)
    err_class = git_error_class[int(err_obj.class)]
    err_msg   = bytestring(err_obj.message)
    return (err_class, err_msg)
end

LibGitError(code::Integer) = begin
    err_code = git_error_code[int(code)]
    err_class, err_msg = last_error()
    return LibGitError{err_class, err_code}(err_msg)
end

macro check(git_func)
    quote
        local err::Cint
        err = $(esc(git_func::Expr))
        if err < 0
            throw(LibGitError(err))
        end
        err
    end
end
