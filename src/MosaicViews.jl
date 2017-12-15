module MosaicViews

using ImageCore
using ColorTypes
using FixedPointNumbers

export

    MosaicView

struct MosaicView{T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,2}
    parent::A
    dims::Tuple{Int,Int}
end

function MosaicView(A::AbstractArray{T,N}) where {T,N}
    3 <= N <= 4 || throw(ArgumentError("The given array must have dimensionality N=3 or N=4"))
    dims = (size(A,1) * size(A,3), size(A,2) * size(A,4))
    MosaicView{T,N,typeof(A)}(A,dims)
end

Base.size(mv::MosaicView) = mv.dims

Base.@propagate_inbounds function Base.getindex(mv::MosaicView{T,3,A}, i::Int, j::Int) where {T,A}
    @boundscheck checkbounds(mv, i, j)
    pdims = size(mv.parent)
    idx1 = (i-1) % pdims[1] + 1
    idx2 = (j-1) % pdims[2] + 1
    idx3 = (i-1) ÷ pdims[1] + 1
    @inbounds res = mv.parent[idx1, idx2, idx3]
    res
end

Base.@propagate_inbounds function Base.getindex(mv::MosaicView{T,4,A}, i::Int, j::Int) where {T,A}
    @boundscheck checkbounds(mv, i, j)
    pdims = size(mv.parent)
    idx1 = (i-1) % pdims[1] + 1
    idx2 = (j-1) % pdims[2] + 1
    idx3 = (i-1) ÷ pdims[1] + 1
    idx4 = (j-1) ÷ pdims[2] + 1
    @inbounds res = mv.parent[idx1, idx2, idx3, idx4]
    res
end

end # module
