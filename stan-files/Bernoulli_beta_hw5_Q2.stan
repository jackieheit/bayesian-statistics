//
// Simple Bernoulli-beta model.
//

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N;  // number of trials
  int<lower=0, upper=N> z;  // total number of successes in N trials
  real<lower=0> a;  // prior hyperparameter for Beta distribution
  real<lower=0> b;  // prior hyperparameter for Beta distribution
}

transformed data {
  int y = z;  // Explicitly define a transformed data variable
}

parameters {
  real<lower=0, upper=1> theta;  // probability of success
}

model {
  theta ~ beta(a, b);  // Beta prior for theta
  z ~ binomial(N, theta);  // Binomial likelihood for successes
}
