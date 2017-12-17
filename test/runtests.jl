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
        @test typeof(mv) <: MosaicView
        @test eltype(mv) == eltype(A)
        @test size(mv) == (4, 6)
        @test @inferred(getindex(mv,1,1)) === 1
        @test @inferred(getindex(mv,2,1)) === 3
        @test all(mv .== vcat(hcat(A[:,:,1,1],A[:,:,1,2],A[:,:,1,3]), hcat(A[:,:,2,1],A[:,:,2,2],A[:,:,2,3])))
    end
end
