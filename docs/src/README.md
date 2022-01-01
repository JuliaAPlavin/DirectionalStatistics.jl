# Overview

Directional statistics package for Julia. Currently includes several circular and spatial descriptive statistics, see reference below for details.

# Usage

Package contains submodules, and many functions are indended to be qualified on call. This lets us use names such as `mean()` and still have no conflicts with functions in `Statistics` or `StatsBase`.
```
using DirectionalStatistics

Circular.mean(...)
```

All circular statistics operate in a 2π range by default, that corresponds to the natural range of angles. Arbitrary ranges are supported and can be specified as an interval:
```
using IntervalSets

Circular.mean(array, 0..π)
Circular.mean(array, -180..+180)
```

# Reference

```@autodocs
Modules = [DirectionalStatistics.Circular, DirectionalStatistics]
Order   = [:function, :type]
```
