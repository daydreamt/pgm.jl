using pgm
using Base.Test

##########################################
# Test internal functions
##########################################
@test pgm.pb((quote (pi :: (-1.0.. 10.)^(K)) end)) == (:pi, -1, -1.0, 10.0, Float64, (:K,1))

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

consts, hyperparams, params = gmm(2,2,5)

