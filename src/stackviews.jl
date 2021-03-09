"""
    StackView(frames::AbstractVector{<:AbstractArray}; [dims::Int])

Stack/concatenate a list of arrays `frames` along dimension `dims` without copying the data.
If not specified, `dims` is defined as `ndims(first(frames))+1`, i.e., a new dimension in the tail.
"""
struct StackView{T, N, D, A} <: AbstractArray{T, N}
    frames::A

    function StackView{T, N}(frames; dims::Int) where {T, N}
        length(unique(size.(frames))) == 1 || throw(ArgumentError("all frames should be of the same size."))
        1<= dims <= N || throw(ArgumentError("stacking dimension should be within {1, 2, ..., $N}"))
        new{T, N, dims, typeof(frames)}(frames)
    end
end

StackView(frames; dims=ndims(first(frames))+1) = StackView{_filltype(frames), ndims(first(frames))+1}(frames; dims=dims)

function Base.size(A::StackView{T,N,D}) where {T,N,D}
    frame_size = size(first(A.frames))
    prev, post = Base.IteratorsMD.split(frame_size, Val(D-1))
    return (prev..., length(A.frames), post...)
end

@inline function Base.getindex(A::StackView{T,N,D}, i::Vararg{Int,N}) where {T,N,D}
    @boundscheck checkbounds(A, i...)
    prev, post = Base.IteratorsMD.split(i, Val(D-1))
    idx, post = first(post), Base.tail(post)
    return @inbounds A.frames[idx][prev..., post...]
end

