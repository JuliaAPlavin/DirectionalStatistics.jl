module DistributionsExt

using Distributions
using DirectionalStatistics

Circular.mean(d::VonMises) = mean(d)
Circular.var(d::VonMises) = var(d)
Circular.std(d::VonMises) = √(-2*log(1-var(d)))

end
