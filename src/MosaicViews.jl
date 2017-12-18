module MosaicViews

using ImageCore
using PaddedViews

export

    MosaicView,
    mosaicview

"""
    MosaicView(A::AbstractArray)

Create a two dimensional "view" of the three or four dimensional
array `A`. The resulting `MosaicView` will display the data in
`A` such that it emulates using `vcat` for all elements in the
third dimension of `A`, and `hcat` for all elements in the fourth
dimension of `A`.

For example, if `size(A)` is `(2,3,4)`, then the resulting
`MosaicView` will have the size `(2*4,3)` which is `(8,3)`.
Alternatively, if `size(A)` is `(2,3,4,5)`, then the resulting
size will be `(2*4,3*5)` which is `(8,15)`.

Another way to think about this is that `MosaicView` creates a
mosaic of all the individual matrices enumerated in the third
(and optionally fourth) dimension of the given 3D or 4D array
`A`. This can be especially useful for creating a single
composite image from a set of equally sized images.

```@jldoctest
julia> using MosaicViews

julia> A = [(k+1)*l-1 for i in 1:2, j in 1:3, k in 1:2, l in 1:2]
2×3×2×2 Array{Int64,4}:
[:, :, 1, 1] =
 1  1  1
 1  1  1

[:, :, 2, 1] =
 2  2  2
 2  2  2

[:, :, 1, 2] =
 3  3  3
 3  3  3

[:, :, 2, 2] =
 5  5  5
 5  5  5

julia> MosaicView(A)
4×6 MosaicViews.MosaicView{Int64,4,Array{Int64,4}}:
 1  1  1  3  3  3
 1  1  1  3  3  3
 2  2  2  5  5  5
 2  2  2  5  5  5
```
"""
struct MosaicView{T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,2}
    parent::A
    pdims::NTuple{N,Int}
    dims::Tuple{Int,Int}
end

function MosaicView(A::AbstractArray{T,N}) where {T,N}
    3 <= N <= 4 || throw(ArgumentError("The given array must have dimensionality N=3 or N=4"))
    dims = (size(A,1) * size(A,3), size(A,2) * size(A,4))
    MosaicView{T,N,typeof(A)}(A,size(A),dims)
end

Base.size(mv::MosaicView) = mv.dims

@inline function Base.getindex(mv::MosaicView{T,3,A}, i::Int, j::Int) where {T,A}
    @boundscheck checkbounds(mv, i, j)
    pdims = mv.pdims
    parent = mv.parent
    idx1 = (i-1) % pdims[1] + 1
    idx2 = (j-1) % pdims[2] + 1
    idx3 = (i-1) ÷ pdims[1] + 1
    @inbounds res = parent[idx1, idx2, idx3]
    res
end

@inline function Base.getindex(mv::MosaicView{T,4,A}, i::Int, j::Int) where {T,A}
    @boundscheck checkbounds(mv, i, j)
    pdims = mv.pdims
    parent = mv.parent
    idx1 = (i-1) % pdims[1] + 1
    idx2 = (j-1) % pdims[2] + 1
    idx3 = (i-1) ÷ pdims[1] + 1
    idx4 = (j-1) ÷ pdims[2] + 1
    @inbounds res = parent[idx1, idx2, idx3, idx4]
    res
end

"""
    mosaicview(A::AbstractArray, [fill]; [npad], [nrow], [ncol], [rowmajor=false]) -> MosaicView

"""
function mosaicview(A::AbstractArray{T,3},
                    fill = zero(T);
                    npad = 0,
                    nrow = -1,
                    ncol = -1,
                    rowmajor = false) where T
    ntile = size(A,3)
    ntile_ceil = ntile # ntile need not be integer divideable
    if nrow == -1 && ncol == -1
        # automatically choose nrow to reflect what MosaicView does
        nrow = ntile
        ncol = 1
    elseif nrow == -1
        # compute nrow based on ncol
        nrow = ceil(Int, ntile / ncol)
        ntile_ceil = nrow * ncol
    elseif ncol == -1
        # compute ncol based on nrow
        ncol = ceil(Int, ntile / nrow)
        ntile_ceil = nrow * ncol
    else
        # accept nrow and ncol as is if it covers at least all
        # existing tiles
        ntile_ceil = nrow * ncol
        ntile_ceil < ntile && throw(ArgumentError("The product of \"ncol\" ($ncol) and \"nrow\" ($nrow) must be equal to or greater than $ntile"))
    end
    A_new = if !rowmajor
        # we pad size(A,3) to nrow*ncol. we also pas the first two
        # dimensions according to npad. think of this as border
        # between tiles (useful for images)
        reshape(
            PaddedView(T(fill), A,
                       (size(A,1)+npad, size(A,2)+npad, ntile_ceil)),
            (size(A,1)+npad, size(A,2)+npad, nrow, ncol)
        )
    else
        # same as above but we additionally permute dimensions
        # to mimic row first layout for the tiles. this is useful
        # for images since user often reads these from left-to-right
        # before top-to-bottom.
        A_tp = reshape(
            PaddedView(T(fill), A,
                       (size(A,1)+npad, size(A,2)+npad, ntile_ceil)),
            (size(A,1)+npad, size(A,2)+npad, ncol, nrow) # note the swap of ncol and nrow
        )
        permuteddimsview(A_tp, (1,2,4,3))
    end
    # decrease size of the resulting MosaicView by npad to not have
    # a border on the right side and bottom side.
    dims = (size(A_new,1) * size(A_new,3) - npad, size(A_new,2) * size(A_new,4) - npad)
    MosaicView{T,4,typeof(A_new)}(A_new, size(A_new), dims)
end

function mosaicview(A::AbstractArray{T,N},
                    args...;
                    npad = 0,
                    nrow = -1,
                    ncol = -1,
                    rowmajor = false) where {T,N}
    3 <= N || throw(ArgumentError("The given array must have dimensionality of N=3 or higher"))
    # if no nrow or ncol is provided then automatically choose
    # nrow and ncol to reflect what MosaicView does (i.e. use size)
    if nrow == -1 && ncol == -1
        nrow = size(A, 3)
        # ncol = size(A, 4)
    end
    mosaicview(reshape(A, (size(A,1), size(A,2), :)), args...;
               npad=npad, nrow=nrow, ncol=ncol, rowmajor=rowmajor)
end

end # module
