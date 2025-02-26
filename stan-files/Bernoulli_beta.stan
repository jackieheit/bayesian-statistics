//
// Simple Bernoulli-beta model.
//

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N; // number of trials
  array[N] int y; // data (= 0 if "failure", = 1 if "success")
}
parameters {
  real<lower=0, upper=1> theta; // theta (= probability of "success"); note that theta is bounded by 0 and 1
}
model {
  theta ~ beta(10.6, 39.4); // prior on theta
  y ~ bernoulli(theta); // likelihood
}
