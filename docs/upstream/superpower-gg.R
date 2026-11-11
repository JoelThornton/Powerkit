# Independent investigation of a recorded Superpower GG discrepancy.
# From the repository root: Rscript docs/upstream/superpower-gg.R
# This does not change Powerkit methods or published validation constants.
output <- file.path('validation-results', 'gg-investigation')
dir.create(output, recursive=TRUE, showWarnings=FALSE)
library(Superpower)
library(afex)
means <- list(c(20,16,15),c(20,19,18.5))
sds <- list(c(6,7,8),c(6,8,10))
r <- matrix(c(1,.7,.3,.7,1,.6,.3,.6,1),3)
sigma <- lapply(sds,function(s) diag(s)%*%r%*%diag(s))
n <- c(20L,20L); total <- sum(n); q <- 2L
Q <- qr.Q(qr(contr.helmert(3)))
chol_sigma <- lapply(sigma,chol)
eps <- function(s) sum(diag(s))^2/(q*sum(s*s))
population_epsilon <- eps(t(Q)%*%((sigma[[1]]+sigma[[2]])/2)%*%Q)
set.seed(90101)
one_study <- function(i) {
  y <- lapply(seq_along(n),function(g) sweep(matrix(rnorm(n[g]*3),n[g])%*%chol_sigma[[g]],2,means[[g]],'+'))
  z <- lapply(y,function(v) v%*%Q)
  residuals <- lapply(z,function(v) sweep(v,2,colMeans(v),'-'))
  covariance <- Reduce('+',lapply(residuals,crossprod))/(total-2)
  ss_group <- prod(n)/total * sum((colMeans(z[[1]])-colMeans(z[[2]]))^2)
  statistic <- (ss_group/q)/(sum(diag(covariance))/q)
  sample_epsilon <- eps(covariance)
  p <- pf(statistic,q*sample_epsilon,(total-2)*q*sample_epsilon,lower.tail=FALSE)
  p_fixed <- pf(statistic,q*population_epsilon,(total-2)*q*population_epsilon,lower.tail=FALSE)
  difference <- NA_real_
  if (i <= 30L) {
    data <- do.call(rbind,lapply(seq_along(n),function(g) data.frame(
      subject=rep(paste0('g',g,'p',seq_len(n[g])),3),a=factor(g),
      b=factor(rep(1:3,each=n[g])),y=as.vector(y[[g]]))))
    fit <- suppressMessages(aov_car(y~a*b+Error(subject/b),data=data,type=3,
      anova_table=list(correction='GG',es='none')))
    difference <- p-fit$anova_table['a:b','Pr(>F)']
  }
  c(reject=p<.05,reject_fixed=p_fixed<.05,epsilon=sample_epsilon,afex_difference=difference)
}
out <- vapply(seq_len(20000L),one_study,numeric(4))
design <- ANOVA_design('2b*3w',n=20,mu=unlist(means),sd=unlist(sds),
  r=c(.7,.3,0,0,0,.6,0,0,0,0,0,0,.7,.3,.6),plot=FALSE)
exact <- ANOVA_exact(design,correction='GG',verbose=FALSE)
summary <- list(seed=90101L,replications=ncol(out),n=40L,
  exact_population_power=exact$main_results['a:b','power']/100,
  sample_epsilon_power=mean(out['reject',]),fixed_epsilon_power=mean(out['reject_fixed',]),
  sample_epsilon_mcse=sqrt(mean(out['reject',])*(1-mean(out['reject',]))/ncol(out)),
  population_epsilon=population_epsilon,mean_sample_epsilon=mean(out['epsilon',]),
  max_afex_p_difference=max(abs(out['afex_difference',]),na.rm=TRUE),
  versions=as.list(vapply(c('Superpower','afex','R'),function(p) if(p=='R') as.character(getRversion()) else as.character(packageVersion(p)),'')),
  case=list(means=means,sd=sds,correlation=r,alpha=.05,group_n=n),
  afex_p_checks=30L,
  sample_epsilon_interval_999=as.numeric(binom.test(sum(out['reject',]),ncol(out),conf.level=.999)$conf.int),
  paired_fixed_minus_sample=mean(out['reject_fixed',]-out['reject',]),
  paired_difference_mcse=sd(out['reject_fixed',]-out['reject',])/sqrt(ncol(out)),
  script_md5=unname(tools::md5sum('docs/upstream/superpower-gg.R')))
print(summary)
jsonlite::write_json(summary,file.path(output,'summary.json'),pretty=TRUE,auto_unbox=TRUE,digits=15)
saveRDS(out,file.path(output,'replications.rds'))

writeLines(capture.output(sessionInfo()),file.path(output,'session-info.txt'))
stopifnot(summary$max_afex_p_difference < 1e-10)
