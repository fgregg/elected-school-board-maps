library(eiPack)

ntunes_val <- 10
tunedraws <- 10000
thin_mcmc <- 100
burnin_mcmc <- 100000

elec_data <- read.csv('cvap_general.csv')

# The row (candidate) marginals have to equal the column (race) marginals, so
# we need to pad out with an abstain row and other column. 

elec_data <- within(elec_data, {
  # some of the subgroup categories overlap with hispanic
  total_cvap <- ifelse(
    (white_cvap +
       black_cvap +
       asian_cvap +
       latino_cvap) > total_cvap,
    white_cvap +
      black_cvap +
      asian_cvap +
      latino_cvap,
    total_cvap
  )
  
  abstain_cvap <- (
    total_cvap -
      ja_mal.green -
      sophia.king -
      kam.buckner -
      willie.l..wilson -
      brandon.johnson -
      paul.vallas -
      lori.e..lightfoot -
      roderick.t..sawyer -
      jesus..chuy..garcia
  )
  other_cvap <- (total_cvap -
                   asian_cvap -
                   latino_cvap -
                   white_cvap -
                   black_cvap)
})

# drop a couple of rows that have negative abstensions
elec_data <- elec_data[elec_data$abstain >= 0, ]

form <- with(elec_data, {
  cbind(
    ja_mal.green,
    sophia.king,
    kam.buckner,
    willie.l..wilson,
    brandon.johnson,
    paul.vallas,
    lori.e..lightfoot,
    roderick.t..sawyer,
    jesus..chuy..garcia,
    abstain_cvap
  ) ~ cbind(asian_cvap,
            white_cvap,
            black_cvap,
            other_cvap,
            latino_cvap)
})

tune.nocov <- eiPack::tuneMD(form,
                             data = elec_data,
                             ntunes = ntunes_val,
                             totaldraws = tunedraws)

out.nocov <- eiPack::ei.MD.bayes(
  form,
  covariate = NULL,
  data = elec_data,
  tune.list = tune.nocov,
  ret.mcmc = TRUE,
  burnin = burnin_mcmc,
  thin = thin_mcmc
)

sink("ei_summary.txt")
print(summary(out.nocov, quantiles = c(.025, .05, .5, .95, .975)))
sink()

mcmc_df <-
  data.frame(as.matrix(out.nocov$draws$Cell.counts, iters = TRUE))
write.csv(mcmc_df, "ei_samples.csv")

mcmc_df_prec <- as.matrix(out.nocov$draws$Beta)
x <- colMeans(mcmc_df_prec)
y <- apply(mcmc_df_prec, 2, sd)
probs <- c(0:8 / 8)
q_0 <-
  apply(mcmc_df_prec,
        MARGIN = 2,
        FUN = quantile,
        probs = probs)
write.csv(t(q_0), "prec_quants.csv")
write.csv(x, "prec_means.csv")
write.csv(y, "prec_sd.csv")
