module CircularStats

function center_angle(x; at = 0, range = 2π)
    low = at - range / 2
    return mod(x - low, range) + low
end

mean(x) = angle(sum(exp.(im .* x)))

var(x) = 1 - abs(resultant(x))

std(x) = sqrt(max(0, -2 * log(abs(resultant(x)))))

function resultant(x)
    r = sum(exp.(im .* x)) / length(x)
    if abs(r) > 1
        r = r / abs(r)
    end
    return r
end

function median(x::AbstractVector)
    if length(x) == 0 return NaN end
    sums_of_dists = [
        sum(abs(center_angle(a - b))
            for b in x)
        for a in x]
    return x[argmin(sums_of_dists)]
end

end
