module DirectionalStatistics

include("circular_stats.jl")
include("geometric_median.jl")

vec_std(A; center=mean(A))::eltype(eltype(A)) = sqrt(sum(norm.(A .- Ref(center)).^2) / (length(A) - 1))
export vec_std

end
