# MosaicViews

[![Travis-CI][travis-img]][travis-url]
[![CodeCov][codecov-img]][codecov-url]
[![PkgEval][pkgeval-img]][pkgeval-url]

## Motivations

When visualizing images, it is not uncommon to provide a 2D view of different image sources.
For example, comparing multiple images of different sizes, getting a preview of machine
learning dataset. This package aims to provide an easy-to-use tool for such tasks.

### Compare two images

When comparing and showing multiple images, `cat`/`hcat`/`vcat` can be helpful if images
sizes and colorants are the same. But if not, you'll need `mosaicview` for this purpose.

```julia
# ImageCore reexports MosaicViews with some glue codes for images
julia> using ImageCore, ImageShow, TestImages, ColorVectorSpace

julia> toucan = testimage("toucan") # 150×162 RGBA image

julia> moon = testimage("moon") # 256×256 Gray image

julia> mosaicview(toucan, moon; nrow=1)
```

![compare-images](https://user-images.githubusercontent.com/8684355/76200526-c0be4700-622c-11ea-9d8f-03e22bc39be8.png)

### Get a preview of dataset

Many datasets in machine learning field are stored as 3D/4D array, `mosaicview` provides
some convenient keyword arguments to get a nice looking preview of your dataset.

```julia
julia> using MosaicViews, ImageShow, MLDatasets

julia> A = MNIST.convert2image(MNIST.traintensor(1:9))
28×28×9 Array{Gray{Float64},3}:
[...]

julia> mosaicview(A, fillvalue=.5, nrow=2, npad=1, rowmajor=true)
57×144 MosaicViews.MosaicView{Gray{Float64},4,...}:
[...]
```

![dataset-preview](https://user-images.githubusercontent.com/10854026/34172451-5f80173e-e4f2-11e7-9e86-8b3882d53aa7.png)

## Usage

MosaicViews.jl provides an array decorator type, `MosaicView`,
that creates a matrix-shaped "view" of any three or four
dimensional array `A`. The resulting `MosaicView` will display
the data in `A` such that it emulates using `vcat` for all
elements in the third dimension of `A`, and `hcat` for all
elements in the fourth dimension of `A`.

If performance isn't a priority, `mosaicview` is a convenience
helper function to create a `MosaicView`.

### the `mosaicview` helper

`mosaicview` is sufficient for most visualization use cases. It
accepts multiple arrays as input:

```julia
julia> A1 = fill(1, 3, 1)
3×1 Array{Int64,2}:
 1
 1
 1

julia> A2 = fill(2, 1, 3)
1×3 Array{Int64,2}:
 2  2  2

# A1 and A2 will be padded to the common size and shifted
# to the center, this is a common operation to visualize
# multiple images
julia> mosaicview(A1, A2)
6×3 MosaicView{Int64,4, ...}:
 0  1  0
 0  1  0
 0  1  0
 0  0  0
 2  2  2
 0  0  0
```

Besides this, `mosaicview` also allows for a couple of convenience
keywords. The following example provides a preview, for more detailed
explanation, please refer to the documentation `?mosaicview`.

```julia
# disable center shift
julia> mosaicview(A1, A2; center=false)
6×3 MosaicView{Int64,4, ...}:
 1  0  0
 1  0  0
 1  0  0
 2  2  2
 0  0  0
 0  0  0

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

# number of tiles in column direction
julia> mosaicview(A, ncol=2)
6×6 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  4  4  4
 1  1  1  4  4  4
 2  2  2  5  5  5
 2  2  2  5  5  5
 3  3  3  0  0  0
 3  3  3  0  0  0

# number of tiles in row direction
julia> mosaicview(A, nrow=2)
4×9 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  3  3  3  5  5  5
 1  1  1  3  3  3  5  5  5
 2  2  2  4  4  4  0  0  0
 2  2  2  4  4  4  0  0  0

# take a row-major order, i.e., tile-wise permute
julia> mosaicview(A, nrow=2, rowmajor=true)
4×9 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  2  2  2  3  3  3
 1  1  1  2  2  2  3  3  3
 4  4  4  5  5  5  0  0  0
 4  4  4  5  5  5  0  0  0

# add empty padding space between adjacent mosaic tiles
julia> mosaicview(A, nrow=2, npad=1, rowmajor=true)
5×11 MosaicViews.MosaicView{Int64,4,...}:
 1  1  1  0  2  2  2  0  3  3  3
 1  1  1  0  2  2  2  0  3  3  3
 0  0  0  0  0  0  0  0  0  0  0
 4  4  4  0  5  5  5  0  0  0  0
 4  4  4  0  5  5  5  0  0  0  0

# fill spaces with -1
julia> mosaicview(A, fillvalue=-1, nrow=2, npad=1, rowmajor=true)
5×11 MosaicViews.MosaicView{Int64,4,...}:
  1   1   1  -1   2   2   2  -1   3   3   3
  1   1   1  -1   2   2   2  -1   3   3   3
 -1  -1  -1  -1  -1  -1  -1  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
```

### The `MosaicView` Type

If performance is important it is recommended to use `MosaicView`
directly, as `mosaicview` is not type stable.

Note that the constructor doesn't accept other parameters than
the array `A` itself, it doesn't accept multiple inputs neither.
Consequently the layout of the mosaic is encoded in the third
(and optionally fourth) dimension. Creating a `MosaicView` this
way is type stable, non-copying, and should in general give a
decent performance when accessed with `getindex`.

Another way to think about this is that `MosaicView` creates a
mosaic of all the individual matrices enumerated in the third
(and optionally fourth) dimension of the given 3D or 4D array
`A`. This can be especially useful for creating a single
composite image from a set of equally sized images.

Let us look at a couple examples to see the type in action. If
`size(A)` is `(2,3,4)`, then the resulting `MosaicView` will have
the size `(2*4,3)` which is `(8,3)`.

```julia
julia> A = [k for i in 1:2, j in 1:3, k in 1:4]
2×3×4 Array{Int64,3}:
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

julia> MosaicView(A)
8×3 MosaicViews.MosaicView{Int64,3,Array{Int64,3}}:
 1  1  1
 1  1  1
 2  2  2
 2  2  2
 3  3  3
 3  3  3
 4  4  4
 4  4  4
```

Alternatively, `A` is also allowed to have four dimensions. More
concretely, if `size(A)` is `(2,3,4,5)`, then the resulting size
will be `(2*4,3*5)` which is `(8,15)`. For the sake of brevity
here is a slightly smaller example:

```julia
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

[travis-img]: https://travis-ci.org/JuliaArrays/MosaicViews.jl.svg?branch=master
[travis-url]: https://travis-ci.org/JuliaArrays/MosaicViews.jl
[codecov-img]: http://codecov.io/github/JuliaArrays/MosaicViews.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/JuliaArrays/MosaicViews.jl?branch=master
[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/M/MosaicViews.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html
