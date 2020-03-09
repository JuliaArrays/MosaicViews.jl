module MosaicViews

using PaddedViews
using OffsetArrays

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
    dims::Tuple{Int,Int}
    pdims::NTuple{N,Int}

    function MosaicView{T,N}(A::AbstractArray{T,N}, dims) where {T,N}
        3 <= N <= 4 || throw(ArgumentError("The given array must have dimensionality N=3 or N=4"))
        new{T,N,typeof(A)}(A, dims, size(A))
    end
end

function MosaicView(A::AbstractArray{T,N}) where {T,N}
    dims = (size(A,1) * size(A,3), size(A,2) * size(A,4))
    MosaicView{T,N}(A, dims)
end

Base.parent(mv::MosaicView) = mv.parent
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
    mosaicview(A::AbstractArray;
               [fillvalue=<zero unit>],
               [npad=0],
               [nrow],
               [ncol],
               [rowmajor=false],
               [center=true]) -> MosaicView
    mosaicview(A::AbstractArray...; kwargs...)
    mosaicview(As; kwargs...)

Create a two dimensional "view" of the higher dimensional array
`A`. The resulting [`MosaicView`](@ref) will display all the
matrix slices of the first two dimensions of `A` arranged as a
single large mosaic (in the form of a matrix).

In contrast to using the constructor of [`MosaicView`](@ref)
directly, the function `mosaicview` also allows for a couple of
convenience keywords. Note that as a consequence the function is
not type stable and should only be used if performance is not a
priority. A typical use case would be to create an image mosaic
from a set of equally sized input images.

- The parameter `fillvalue` defines the value that
  that should be used for empty space. This can be padding caused
  by `npad`, or empty mosaic tiles in case the number of matrix
  slices in `A` is smaller than `nrow*ncol`.

- The parameter `npad` defines the empty padding space between
  adjacent mosaic tiles. This can be especially useful if the
  individual tiles (i.e. matrix slices in `A`) are images that
  should be visually separated by some grid lines.

- The parameters `nrow` and `ncol` can be used to choose the
  number of rows and/or columns the mosaic should be arranged in.
  Note that it suffices to specify one of the two parameters, as
  the other one can be inferred accordingly. The default in case
  none of the two are specified is `nrow = size(A,3)`.

- If `rowmajor` is set to `true`, then the slices will be
  arranged left-to-right-top-to-bottom, instead of
  top-to-bottom-left-to-right (default).

- If `center` is set to `true`, then the padded arrays will be shifted
  to the center instead of in the top-left corner (default). This
  parameter is only useful when arrays are of different sizes.

If the performance isn't an issue, `A` can also be a tuple/array
of arrays, in this case all array elements will be padded to the
same size first, and then be concatenated to an array of higher
dimension.

# Examples

```julia-repl
julia> using MosaicViews

julia> A = [k for i in 1:2, j in 1:3, k in 1:5]
2×3×5 Array{Int64,3}:
[:, :, 1] =
 1  1  1
 1  1  1

[:, :, 2] =
 2  2  2
 2  2  2

[:, :, 3] =
 3  3  3
 3  3  3

[:, :, 4] =
 4  4  4
 4  4  4

[:, :, 5] =
 5  5  5
 5  5  5

julia> mosaicview(A, ncol=2)
6×6 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  4  4  4
 1  1  1  4  4  4
 2  2  2  5  5  5
 2  2  2  5  5  5
 3  3  3  0  0  0
 3  3  3  0  0  0

julia> mosaicview(A, nrow=2)
4×9 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  3  3  3  5  5  5
 1  1  1  3  3  3  5  5  5
 2  2  2  4  4  4  0  0  0
 2  2  2  4  4  4  0  0  0

julia> mosaicview(A, nrow=2, rowmajor=true)
4×9 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  2  2  2  3  3  3
 1  1  1  2  2  2  3  3  3
 4  4  4  5  5  5  0  0  0
 4  4  4  5  5  5  0  0  0

julia> mosaicview(A, nrow=2, npad=1, rowmajor=true)
5×11 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  0  2  2  2  0  3  3  3
 1  1  1  0  2  2  2  0  3  3  3
 0  0  0  0  0  0  0  0  0  0  0
 4  4  4  0  5  5  5  0  0  0  0
 4  4  4  0  5  5  5  0  0  0  0

julia> mosaicview(A, fillvalue=-1, nrow=2, npad=1, rowmajor=true)
5×11 MosaicViews.MosaicView{Int64,4,...}:
  1   1   1  -1   2   2   2  -1   3   3   3
  1   1   1  -1   2   2   2  -1   3   3   3
 -1  -1  -1  -1  -1  -1  -1  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
```


```julia-repl
julia> A = [i*ones(Int, 2, 3) for i in 1:4]
4-element Array{Array{Int64,2},1}:
 [1 1 1; 1 1 1]
 [2 2 2; 2 2 2]
 [3 3 3; 3 3 3]
 [4 4 4; 4 4 4]

julia> mosaicview(A, nrow=3)
6×6 MosaicView{Int64,4,...}:
  1  1  1  4  4  4
  1  1  1  4  4  4
  2  2  2  0  0  0
  2  2  2  0  0  0
  3  3  3  0  0  0
  3  3  3  0  0  0

julia> mosaicview(A..., nrow=3)
6×6 MosaicView{Int64,4,...}:
  1  1  1  4  4  4
  1  1  1  4  4  4
  2  2  2  0  0  0
  2  2  2  0  0  0
  3  3  3  0  0  0
  3  3  3  0  0  0
```
"""
function mosaicview(A::AbstractArray{T,3};
                    fillvalue = zero(T),
                    npad = 0,
                    nrow = -1,
                    ncol = -1,
                    rowmajor = false,
                    kwargs...) where T
    nrow == -1 || nrow > 0 || throw(ArgumentError("The parameter \"nrow\" must be greater than 0"))
    ncol == -1 || ncol > 0 || throw(ArgumentError("The parameter \"ncol\" must be greater than 0"))
    npad >= 0 || throw(ArgumentError("The parameter \"npad\" must be greater than or equal to 0"))
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
        ntile_ceil < ntile && throw(ArgumentError("The product of the parameters \"ncol\" (value: $ncol) and \"nrow\" (value: $nrow) must be greater than or equal to $ntile"))
    end
    # we pad size(A,3) to nrow*ncol. we also pad the first two
    # dimensions according to npad. think of this as border
    # between tiles (useful for images)
    pad_dims = (size(A,1) + npad, size(A,2) + npad, ntile_ceil)
    A_pad = PaddedView(T(fillvalue), A, pad_dims)
    # next we reshape the image such that it reflects the
    # specified nrow and ncol
    A_new = if !rowmajor
        res_dims = (size(A_pad,1), size(A_pad,2), nrow, ncol)
        reshape(A_pad, res_dims)
    else
        # same as above but we additionally permute dimensions
        # to mimic row first layout for the tiles. this is useful
        # for images since user often reads these from left-to-right
        # before top-to-bottom. (note the swap of "ncol" and "nrow")
        res_dims = (size(A_pad,1), size(A_pad,2), ncol, nrow)
        A_tp = reshape(A_pad, res_dims)
        PermutedDimsArray(A_tp, (1, 2, 4, 3))
    end
    # decrease size of the resulting MosaicView by npad to not have
    # a border on the right side and bottom side of the final mosaic.
    dims = (size(A_new,1) * size(A_new,3) - npad, size(A_new,2) * size(A_new,4) - npad)
    MosaicView{T,4}(A_new, dims)
end

function mosaicview(A::AbstractArray{T,N};
                    nrow = -1,
                    ncol = -1,
                    kwargs...) where {T,N}
    3 <= N || throw(ArgumentError("The given array must have dimensionality of N=3 or higher"))
    # if neither nrow nor ncol is provided then automatically choose
    # nrow and ncol to reflect what MosaicView does (i.e. use size)
    if nrow == -1 && ncol == -1
        nrow = size(A, 3)
        # ncol = size(A, 4)
    end
    mosaicview(reshape(A, (size(A,1), size(A,2), :));
               nrow=nrow, ncol=ncol, kwargs...)
end

mosaicview(As::AbstractArray...; kwargs...) = mosaicview(As; kwargs...)

function mosaicview(As::AbstractVector{T};
                    fillvalue=zero(eltype(first(As))),
                    center=true,
                    kwargs...) where {T <: AbstractArray}
    length(As) == 0 && throw(ArgumentError("The given vector should not be empty"))
    N = ndims(first(As))
    2 <= N || throw(ArgumentError("The given array must have dimensionality of N=2 or higher"))
    mosaicview(_padded_cat(As; center=center, fillvalue=fillvalue, dims=N+1);
               fillvalue=fillvalue, kwargs...)
end

function mosaicview(As::Tuple;
                    fillvalue=zero(eltype(first(As))),
                    center=true,
                    kwargs...)
    N = ndims(first(As))
    2 <= N || throw(ArgumentError("The given array must have dimensionality of N=2 or higher"))
    mosaicview(_padded_cat(As; center=center, fillvalue=fillvalue, dims=N+1);
               fillvalue=fillvalue, kwargs...)
end

function _padded_cat(imgs; center, fillvalue, dims)
    # reduce(cat, imgs) would indeed make the whole pipeline more eagerly
    # and thus allocates more memory
    # TODO: inefficient when there're too many images, e.g., 512
    if length(imgs) > 300
        msg = "It's quite slow to visualize a tuple/list of $(length(imgs)) images"
        msg *= "\nyou might want to manually `cat` them into one large array first."
        @warn msg
    end
    if length(unique(map(axes, imgs))) == 1
        return cat(imgs...; dims=dims)
    else
        if center
            # TODO: ~1.5x slower than non-centered version
            reduce(sym_paddedviews(zero(eltype(imgs[1])), imgs...)) do x, y
                x = OffsetArray(x, 1 .- first.(axes(x)))
                y = OffsetArray(y, 1 .- first.(axes(y)))
                cat(x, y; dims=dims)
            end
        else
            cat(paddedviews(fillvalue, imgs...)...; dims=dims)
        end
    end
end

### deprecations

@deprecate mosaicview(A::AbstractArray, fillvalue; kwargs...) mosaicview(A; fillvalue=fillvalue, kwargs...)

end # module
