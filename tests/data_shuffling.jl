using Pkg
cd("/Users/tizianocausin/Library/CloudStorage/OneDrive-SISSA/SIP/SIP_package/SIP_dev")
Pkg.activate(".")
##
using Distributions
##
aa = 1:100
##
μ = 0      # mean
σ = 1      # standard deviation
a = -2     # lower bound (in standard deviations)
b = 2      # upper bound (in standard deviations)

# Create truncated normal distribution
d = truncated(Normal(μ, σ), a, b)
println(d)
##
n = 100
d = Normal(μ, σ)
points = -n:n
# Get probabilities at these points
probs = pdf.(d, points)

## Normalize to ensure sum is 1
probs = probs / sum(probs)
##
rand(probs)
##
print(probs)
