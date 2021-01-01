module CircularStats
using IntervalSets

function center_angle(x; at = 0, range = 2π)
    low = at - range / 2
    return mod(x - low, range) + low
end

shift_range(x, (from, to)) = (x - from.left) / width(from) * width(to) + to.left

to_range(x, rng::Interval) = mod(x - rng.left, width(rng)) + rng.left

mean(x) = angle(sum(exp.(im .* x)))
mean(x, rng::Interval) = shift_range(mean(shift_range.(x, rng => -pi..pi)), -pi..pi => rng)

var(x) = 1 - abs(resultant(x))

std(x) = sqrt(max(0, -2 * log(abs(resultant(x)))))
std(x, rng::Interval) = std(shift_range.(x, rng => -pi..pi)) / (2pi) * width(rng)


function resultant(x)
    r = sum(exp.(im .* x)) / length(x)
    if abs(r) > 1
        r = r / abs(r)
    end
    return r
end

function median(x::AbstractVector)
    # XXX: actually, medoid
    if length(x) == 0 return nothing end
    sums_of_dists = [
        sum(abs(to_range(a - b, -pi..pi))
            for b in x)
        for a in x]
    return x[argmin(sums_of_dists)]
end

end
export CircularStats
