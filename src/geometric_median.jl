using Statistics: mean, median
using StatsBase: weights
using LinearAlgebra: norm


module GeometricMedianAlgo
struct Weiszfeld end  # Weiszfeld's algorithm: https://en.wikipedia.org/wiki/Geometric_median#Computation
struct VardiZhang end  # https://stackoverflow.com/a/30305181, https://www.pnas.org/content/pnas/97/4/1423.full.pdf
end


wsum(A, W) = mapreduce(*, +, A, W)
wmean(A, W) = wsum(A, W) / sum(W)

# Weiszfeld's algorithm as described on Wikipedia: https://en.wikipedia.org/wiki/Geometric_median
function geometric_median(::GeometricMedianAlgo.Weiszfeld, A::AbstractVector; maxiter=1000, atol=1e-7)
    # initial guess: regular mean
    current_value = mean(A)

    for i in 1:maxiter
        distances = norm.(A .- Ref(current_value))
        replace!(distances, 0 => 1)  # avoid infinite weights
        next_value = wmean(A, weights(1 ./ distances))
        movement = norm(next_value - current_value)
        current_value = next_value
        if movement < atol
            break
        end
    end
    
    return current_value
end

function geometric_median(::GeometricMedianAlgo.VardiZhang, A::AbstractVector; maxiter=1000, atol=1e-7)
    # https://stackoverflow.com/a/30305181
    current_value = mean(A)

    for i in 1:maxiter
        distances = norm.(A .- Ref(current_value))
        nonzero_mask = distances .!= 0
        distances = distances[nonzero_mask]
        
        if !any(nonzero_mask)
            return current_value
        end
    
        ws = weights(1 ./ distances)
        next_value = if all(nonzero_mask)
            wmean(A, ws)
        else
            next_value = wmean(A[nonzero_mask], ws)
            movement_w = norm( (next_value - current_value) .* sum(ws) )
            num_zeros = count(==(0), distances)
            rinv = movement_w == 0 ? 0 : min(num_zeros / movement_w, 1)
            next_value * (1 - rinv) + current_value * rinv
        end

        movement = norm(next_value - current_value)
        current_value = next_value
        if movement < atol
            break
        end
    end
    
    return current_value
end

""" Geometric median of a collection of points. Points can be specified as real numbers (1d), complex numbers (2d), or arbitrary vectors.

See [https://en.wikipedia.org/wiki/Geometric_median].

```jldoctest
julia> geometric_median([1, 2, 3])
2.0

julia> geometric_median([0, 1, 1im, 1+1im]) ≈ 0.5+0.5im
true

julia> geometric_median([[0, 0], [0, 1], [1, 0], [1, 1]]) ≈ [0.5, 0.5]
true
```
"""
geometric_median(A::AbstractVector; kwargs...) = geometric_median(GeometricMedianAlgo.VardiZhang(), A; kwargs...)

""" Geometric Median absolute deviation (MAD) of a collection of points.

Follows the same definition as the univariate MAD, with geometric median instead of the regular median. Rotation invariant, unlike [https://en.wikipedia.org/wiki/Median_absolute_deviation#Geometric_median_absolute_deviation].
"""
function geometric_mad(A::AbstractVector{<:Complex}; kwargs...)
    med = geometric_median(A; kwargs...)
    return median(norm.(A .- med))
end
