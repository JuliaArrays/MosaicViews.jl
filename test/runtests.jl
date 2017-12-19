using MosaicViews
using Base.Test

@testset "MosaicView" begin
    @test_throws ArgumentError MosaicView(rand(2))
    @test_throws ArgumentError MosaicView(rand(2,2))
    @test_throws ArgumentError MosaicView(rand(2,2,2,2,2))

    @testset "3D input" begin
        A = zeros(Int,2,2,2)
        A[:,:,1] = [1 2; 3 4]
        A[:,:,2] = [5 6; 7 8]
        mv = @inferred MosaicView(A)
        @test parent(mv) === A
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (4, 2)
        @test @inferred(getindex(mv,1,1)) === 1
        @test @inferred(getindex(mv,2,1)) === 3
        @test_throws BoundsError mv[0,1]
        @test_throws BoundsError mv[1,0]
        @test_throws BoundsError mv[1,3]
        @test_throws BoundsError mv[5,1]
        @test all(mv .== vcat(A[:,:,1],A[:,:,2]))
        # singleton dimension doesn't change anything
        @test mv == MosaicView(reshape(A,2,2,2,1))
    end

    @testset "4D input" begin
        A = zeros(Int,2,2,1,2)
        A[:,:,1,1] = [1 2; 3 4]
        A[:,:,1,2] = [5 6; 7 8]
        mv = @inferred MosaicView(A)
        @test parent(mv) === A
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (2, 4)
        @test @inferred(getindex(mv,1,1)) === 1
        @test @inferred(getindex(mv,2,1)) === 3
        @test_throws BoundsError mv[0,1]
        @test_throws BoundsError mv[1,0]
        @test_throws BoundsError mv[3,1]
        @test_throws BoundsError mv[1,5]
        @test all(mv .== hcat(A[:,:,1,1],A[:,:,1,2]))
        A = zeros(Int,2,2,2,3)
        A[:,:,1,1] = [1 2; 3 4]
        A[:,:,1,2] = [5 6; 7 8]
        A[:,:,1,3] = [9 10; 11 12]
        A[:,:,2,1] = [13 14; 15 16]
        A[:,:,2,2] = [17 18; 19 20]
        A[:,:,2,3] = [21 22; 23 24]
        mv = @inferred MosaicView(A)
        @test parent(mv) === A
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (4, 6)
        @test @inferred(getindex(mv,1,1)) === 1
        @test @inferred(getindex(mv,2,1)) === 3
        @test all(mv .== vcat(hcat(A[:,:,1,1],A[:,:,1,2],A[:,:,1,3]), hcat(A[:,:,2,1],A[:,:,2,2],A[:,:,2,3])))
    end
end

@testset "mosaicview" begin
    @test_throws ArgumentError mosaicview(rand(2))
    @test_throws ArgumentError mosaicview(rand(2,2))

    @testset "3D input" begin
        A = [(k+1)*l-1 for i in 1:2, j in 1:3, k in 1:2, l in 1:2]
        B = reshape(A, 2, 3, :)
        @test_throws ArgumentError mosaicview(B, nrow=0)
        @test_throws ArgumentError mosaicview(B, ncol=0)
        @test_throws ArgumentError mosaicview(B, nrow=1, ncol=1)
        mv = mosaicview(B)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(B)
        @test size(mv) == (8, 3)
        @test @inferred(getindex(mv,3,1)) === 2
        @test mv == [
            1  1  1
            1  1  1
            2  2  2
            2  2  2
            3  3  3
            3  3  3
            5  5  5
            5  5  5
        ]
        mv = mosaicview(B, nrow=2)
        @test mv == MosaicView(A)
        @test typeof(mv) != typeof(MosaicView(A))
        @test parent(parent(mv)).data == B
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(B)
        @test size(mv) == (4, 6)
    end

    @testset "4D input" begin
        A = [(k+1)*l-1 for i in 1:2, j in 1:3, k in 1:2, l in 1:2]
        @test_throws ArgumentError mosaicview(A, nrow=0)
        @test_throws ArgumentError mosaicview(A, ncol=0)
        @test_throws ArgumentError mosaicview(A, nrow=1, ncol=1)
        mv = mosaicview(A)
        @test mv == MosaicView(A)
        @test typeof(mv) != typeof(MosaicView(A))
        @test parent(parent(mv)).data == reshape(A, 2, 3, :)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (4, 6)
        mv = mosaicview(A, npad=1)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (5, 7)
        @test mv == mosaicview(A, nrow=2, npad=1)
        @test mv == mosaicview(A, ncol=2, npad=1)
        @test @inferred(getindex(mv,3,1)) === 0
        @test @inferred(getindex(mv,2,5)) === 3
        @test mv == [
            1  1  1  0  3  3  3
            1  1  1  0  3  3  3
            0  0  0  0  0  0  0
            2  2  2  0  5  5  5
            2  2  2  0  5  5  5
        ]
        mv = mosaicview(A, ncol=3, npad=1)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (5, 11)
        @test mv == [
            1  1  1  0  3  3  3  0  0  0  0
            1  1  1  0  3  3  3  0  0  0  0
            0  0  0  0  0  0  0  0  0  0  0
            2  2  2  0  5  5  5  0  0  0  0
            2  2  2  0  5  5  5  0  0  0  0
        ]
        mv = mosaicview(A, rowmajor=true, ncol=3, npad=1)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (5, 11)
        @test @inferred(getindex(mv,3,1)) === 0
        @test @inferred(getindex(mv,2,5)) === 2
        @test mv == [
            1  1  1  0  2  2  2  0  3  3  3
            1  1  1  0  2  2  2  0  3  3  3
            0  0  0  0  0  0  0  0  0  0  0
            5  5  5  0  0  0  0  0  0  0  0
            5  5  5  0  0  0  0  0  0  0  0
        ]
        mv = mosaicview(A, rowmajor=true, ncol=3, npad=2)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (6, 13)
        @test mv == [
            1  1  1  0  0  2  2  2  0  0  3  3  3
            1  1  1  0  0  2  2  2  0  0  3  3  3
            0  0  0  0  0  0  0  0  0  0  0  0  0
            0  0  0  0  0  0  0  0  0  0  0  0  0
            5  5  5  0  0  0  0  0  0  0  0  0  0
            5  5  5  0  0  0  0  0  0  0  0  0  0
        ]
        mv = mosaicview(A, -1.0, rowmajor=true, ncol=3, npad=1)
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (5, 11)
        @test mv == [
             1   1   1  -1   2   2   2  -1   3   3   3
             1   1   1  -1   2   2   2  -1   3   3   3
            -1  -1  -1  -1  -1  -1  -1  -1  -1  -1  -1
             5   5   5  -1  -1  -1  -1  -1  -1  -1  -1
             5   5   5  -1  -1  -1  -1  -1  -1  -1  -1
        ]
    end
end
