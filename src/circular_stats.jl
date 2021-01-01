module CircularStats

using IntervalSets
import Statistics

function center_angle(x; at = 0, range = 2π)
    low = at - range / 2
    return mod(x - low, range) + low
end

shift_range(x, (from, to)) = (x - from.left) / width(from) * width(to) + to.left

to_range(x, rng::Interval) = mod(x - rng.left, width(rng)) + rng.left


resultant_vector(x) = sum(exp.(im .* x))
resultant_mean_vector(x) = Statistics.mean(exp.(im .* x))
resultant_length(x) = abs(resultant_vector(x))
resultant_mean_length(x) = abs(resultant_mean_vector(x))


mean(x) = angle(resultant_vector(x))
mean(x, rng::Interval) = shift_range(mean(shift_range.(x, rng => -π..π)), -π..π => rng)

var(x) = 1 - resultant_mean_length(x)
# var(x, rng::Interval) = 1 - resultant_length(x, rng)

std(x) = √(max(0, -2 * log(resultant_mean_length(x))))
std(x, rng::Interval) = std(shift_range.(x, rng => -π..π)) * width(rng) / 2π


function median(x::AbstractVector)
    # XXX: actually, medoid
    if length(x) == 0 return nothing end
    sums_of_dists = [
        sum(abs(to_range(a - b, -π..π))
            for b in x)
        for a in x]
    return x[argmin(sums_of_dists)]
end

end
export CircularStats
