# MosaicViews

[![Build Status](https://travis-ci.org/JuliaArrays/MosaicViews.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/MosaicViews.jl) [![codecov.io](http://codecov.io/github/JuliaArrays/MosaicViews.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaArrays/MosaicViews.jl?branch=master)
[![PkgEval][pkgeval-img]][pkgeval-url]

MosaicViews.jl provides an array decorator type, `MosaicView`,
that creates a matrix-shaped "view" of any three or four
dimensional array `A`. The resulting `MosaicView` will display
the data in `A` such that it emulates using `vcat` for all
elements in the third dimension of `A`, and `hcat` for all
elements in the fourth dimension of `A`. This behaviour
can be further fine tuned by using the lower-case convenience
function `mosaicview`.

In some use cases (especially in machine learning) it is not
uncommon to store multiple equally-sized 2D images in a single
higher dimensional array. Let us look at such an example using
the first few training images from the [MNIST database of
handwritten digits](http://yann.lecun.com/exdb/mnist/). We can
access the dataset with the help of the package
[MLDatasets.jl](https://github.com/JuliaML/MLDatasets.jl).

```julia
julia> using MosaicViews, Images, MLDatasets

julia> A = MNIST.convert2image(MNIST.traintensor(1:9))
28×28×9 Array{Gray{Float64},3}:
[...]

julia> mosaicview(A, .5, nrow=2, npad=1, rowmajor=true)
57×144 MosaicViews.MosaicView{Gray{Float64},4,...}:
[...]
```

![mosaicview](https://user-images.githubusercontent.com/10854026/34172451-5f80173e-e4f2-11e7-9e86-8b3882d53aa7.png)

## The MosaicView Type

Another way to think about this is that `MosaicView` creates a
mosaic of all the individual matrices enumerated in the third
(and optionally fourth) dimension of the given 3D or 4D array
`A`. This can be especially useful for creating a single
composite image from a set of equally sized images.

Note that the constructor doesn't accept other parameters than
the array `A` itself. Consequently the layout of the mosaic is
encoded in the third (and optionally fourth) dimension. Creating
a `MosaicView` this way is type stable, non-copying, and should
in general give a decent performance when accessed with
`getindex`.

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

## Advanced Usage

If performance is important it is recommended to use `MosaicView`
directly. That said, one of the main motivations behind creating
this type in the first place is for visualization purposes. To
that end this package also exports a more flexible convenience
function `mosaicview`.

In contrast to using the constructor of `MosaicView` directly,
the function `mosaicview` also allows for a couple of convenience
keywords.

- The optional positional parameter `fill` defines the value that
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

```julia
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

julia> mosaicview(A, -1, nrow=2, npad=1, rowmajor=true)
5×11 MosaicViews.MosaicView{Int64,4,...}:
  1   1   1  -1   2   2   2  -1   3   3   3
  1   1   1  -1   2   2   2  -1   3   3   3
 -1  -1  -1  -1  -1  -1  -1  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
  4   4   4  -1   5   5   5  -1  -1  -1  -1
```


[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/M/MosaicViews.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html
