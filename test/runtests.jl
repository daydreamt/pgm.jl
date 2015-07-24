using pgm
using Base.Test

##########################################
# Test internal functions
##########################################

# Variables and domains
@test pgm.pb((quote (pi :: (-1.0.. 10.)^(K)) end)) == (:pi, -1, -1.0, 10.0, Float64, (:K,1))
@test pgm.pb(quote sig::Float64^(d, d) end) == (:sig,-1,:inf,:inf, Float64,(:d,:d))
@test pgm.pb((quote alpha[u] :: (1 .. 3) end), 100) == (:alpha, 100, 1, 3, Int64, (1,1))
@test pgm.pb((quote beta[BEN] :: Float64^(2,5) end), 100) == (:beta, 100, :inf, :inf, Float64, (2,5))

@test pgm.parse_pt(parse("@param sig[k]::Float64^(d,d) Symbol"), Dict(), Dict(), Dict(), 1) == (Dict{Any,Any}(),Dict{Any,Any}(),{:sig=>Set{Any}({(:sig,1,:inf,:inf,Float64,(:d,:d))})})
##########################################
# Test some models
##########################################
gmm = @model GaussianMixtureModel begin
    # constant declaration
    @constant d::Int   # vector dimension
    @constant n::Int   # number of observations
    @hyperparam K::Int   # number of components

    # parameter declaration
    @param pi :: (0.0..1.0)^K    # prior proportions
    for k in 1 : K
        @param mu[k] :: Float64^d         # component mean
        @param sig[k] :: Float64^(d, d)   # component covariance
    end

    # sample generation process
    for i in 1 : n
        z[i] ~ Categorical(pi)
        x[i] ~ MultivariateNormal(mu[z[i]], sig[z[i]])
    end
end

consts, hyperparams, params = gmm(d=2,n=2,K=5)
