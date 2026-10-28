# Glossary

*Last updated: 16 October 2026.*

Plain-English hints for the technical terms in the routing prototype's
end-point cards: in "What you would enter", in the standard name and in the
backend line. Each card shows the hint beside the line that uses the term,
once per card for the standard name and backend line.

**What the hints do and don't do.** A hint explains what a term means. It
never says what value to choose: where an effect size comes from is an
open judgement call ([`decision-tree.md`](decision-tree.md), 3.2), and the
cards ask for a justification instead.

The terms and hints are in `app/routing/tree.yaml` (`glossary`). A test
checks that this page matches them, and that every term appears on at least
one card. Where each definition comes from (the source opened, where in it, and
what it supports) is in [`card-sources.md`](card-sources.md); some hints are
only partly supported, and the details are listed there.

| Term | Plain-English hint | On the cards |
| --- | --- | --- |
| Cohen's d | A difference between two averages, measured in standard deviations: 0.5 means the averages are half a standard deviation apart. | E1, E2 |
| d_z | The average change within people (for example, after minus before), divided by how much that change varies from person to person. | E3 |
| SD (standard deviation) | How spread out the scores are around their average. | E1, E2, E3, E7, E8, E18, E19, E20, E21, E22, E23 |
| pooled SD | The two groups' standard deviations combined into one, weighted by the groups' sizes. | E2 |
| SD units | Differences expressed in standard deviations rather than in the outcome's own units (raw). | E7 |
| Student's or Welch's test | Two versions of the t-test: Student's assumes the two groups' scores are equally spread out; Welch's doesn't. | E2 |
| correlation (r) | A number from -1 to 1 for how closely two measures go up and down together; 0 means no straight-line relationship. | E4, E8, E9, E11, E15, E18, E20, E21, E23, E31, E41 |
| repeated measurements | The same people measured more than once (for example, before and after, or in each condition); their scores on different occasions usually go together. | E8, E18, E20, E41 |
| cell means | The expected average in each combination of the factors, such as praise with a hard task (each combination is a 'cell'). | E7, E8, E20, E21, E22 |
| factor and levels | A factor is something you vary or compare (for example, feedback); its levels are its versions (for example, praise and none). | E7, E8, E47 |
| between factor and within factor | A between factor has different people at each level; a within factor has the same people at every level. | E8 |
| interaction | Whether the effect of one factor or variable depends on the level of another. | E7, E8, E9, E13, E14, E15, E31 |
| reliability | How consistently a measure gives the same result; 1 means no measurement error. | E9, E31 |
| standardised paths | The strength of each arrow in the model (for example, X to M), expressed in standard deviations so that arrows between differently scaled measures can be compared. | E10, E11, E12, E13, E14, E15, E16, E17, E38, E40 |
| Monte Carlo draws per CI | How many random draws are used to build each confidence interval for the indirect effect; more draws give a more stable interval. | E10 |
| residuals | The part of each mediator that X doesn't explain; their correlation says how much the mediators overlap beyond X. | E11 |
| indirect path | The route from X to the outcome through a mediator (X to M to Y). | E11, E12, E42 |
| contrast weights | Numbers that say which groups a specific comparison sets against which (for example, 1, 1 and -2 compare the first two groups together with the third). | E19 |
| adjusted group means | Group averages after taking the covariate into account. | E23 |
| covariate | A variable measured alongside the outcome (for example, a before score) that the analysis takes into account. | E23 |
| R-squared | The share of the differences in the outcome that the predictors explain, from 0 to 1. | E23, E24 |
| R-squared change | How much R-squared goes up when the predictor or predictors of interest are added. | E24 |
| discordant proportions | Among people measured twice, the share who change from yes to no and the share who change from no to yes. | E26 |
| odds ratio | How many times higher the odds of 'yes' (the chance of yes divided by the chance of no) are in one group than in another; 1 means no difference. | E27, E29 |
| rate ratio | How many times higher the average count is in one group than in another; 1 means no difference. | E28 |
| product terms | Two predictors multiplied together (for example, x1 times x2), which is how a regression represents an interaction. | E31 |
| fixed effects | The effects you're testing (for example, of a condition), taken to be the same for everyone. | E33 |
| variance | How spread out the scores are: the SD squared. | E52, E53 |
| variance components | How much scores vary because some participants, and some stimuli, score higher or lower than others overall. | E33 |
| intraclass correlation (ICC) | How similar people in the same group (for example, the same class) are, compared with people in different groups, from 0 to 1. | E34 |
| cluster size | How many people there are in each group (for example, pupils per class). | E34 |
| equivalence bounds | The smallest difference you would care about, in each direction; a difference inside them counts as negligible. | E36 |
| RMSEA | A number summarising how far a model's predictions are from the data, allowing for the model's complexity; smaller means a closer fit. | E37 |
| relative indirect effects | With three or more groups, the indirect effect for each group compared with one chosen reference group. | E42 |
| breakpoint | The point in time at which the trend may change (for example, when an intervention started). | E45 |
| level and slope | The level is how high the trend is; the slope is how fast it rises or falls. | E45 |
| autocorrelation | How much each measurement depends on the ones just before it. | E45 |
| mediator | A variable through which X affects the outcome (a go-between). | E11, E39, E40 |
| predictor | A variable used to explain or predict the outcome. | E17, E24 |
| confidence interval (CI) | A range of plausible values for an effect, estimated from the data. | E10 |
| prior | The range of effect sizes you consider plausible before seeing the data, written as a distribution. | E-bayes |
| omnibus test | A single overall test of whether there are any differences among all the groups or conditions at once; it doesn't say which ones differ. | E18 |
| ANOVA | Analysis of variance: a test of whether the average outcome differs across the levels of one or more factors. | E7, E8, E18, E20, E21, E22 |
| main effect | The effect of one factor averaged over the levels of the other factor or factors. | E7 |
| between-participants and within-participants | Between-participants means different people take part at each level of a factor; within-participants means the same people take part at every level. | E7, E20 |
| mixed design | A design with at least one factor that compares different people (between-participants) and at least one that measures the same people repeatedly (within-participants), such as group × time. | E8 |
| ANCOVA | Analysis of covariance: an ANOVA that also takes into account one or more continuous measured variables (covariates), such as a baseline score. | E23 |
| planned contrast | One specific comparison of group averages (for example, the average of groups 1 and 2 against group 3), planned in advance rather than chosen after seeing the results. | E19 |
| z test (two proportions) | A test of whether the share of 'yes' differs between two groups, based on the normal (bell-curve) approximation to the counts. | E5 |
| continuity correction | A slight adjustment to the normal approximation for counts that moves the observed difference toward zero before testing. | E5 |
| chi-square test of independence | A test of whether two categorical variables (for example, group and a yes/no answer) are related, using a table of counts. | E6 |
| McNemar's test | A test of whether the share of 'yes' answers differs between two yes/no measurements on the same people (or on matched pairs). | E26 |
| Cochran's Q | An extension of McNemar's test to three or more yes/no measurements on the same people. | E26 |
| logistic regression | A regression for a yes/no outcome: it models the log of the odds of 'yes' from the predictors. | E27, E47 |
| Poisson or negative binomial | Regressions for count outcomes (how many times something happens); Poisson assumes the counts vary as much as their average, while negative binomial allows them to vary more than that. | E28 |
| ordinal outcome | An outcome whose categories have a natural order (for example, never, sometimes, often) but where the steps between neighbouring categories need not be equal. | E29 |
| PROCESS model number | PROCESS is Andrew Hayes's tool for mediation and moderation analysis; each model number picks one set arrangement of predictor, mediators and moderators, as numbered in Appendix A of Hayes's book (model 4 is mediation). | E10, E11, E12, E13, E14, E38 |
| index of moderated mediation | How much the indirect effect (X to mediator to outcome) changes when the moderator goes up by one unit. | E13 |
| Monte Carlo CI | A confidence interval built by simulating many sets of the model's estimates from their estimated uncertainty, computing the effect for each set, and keeping the middle 95% of the results. | E10 |
| ANOVA_exact() (exact) | Superpower's quick method: it builds one data set whose means, standard deviations and correlations exactly match the ones you enter, analyses it once, and works out power from that result instead of simulating many data sets. | E7, E8 |
| simulation (ANOVA_power()) | Estimating power by generating many random data sets from the design and counting how often the test comes out significant. | E1, E2, E3, E4, E5, E6, E7, E9, E10, E11, E12, E13, E14, E15, E16, E17 |
| brackets N (power_interaction_r2()) | InteractionPoweR's power_interaction_r2() is a quick formula-based power calculation; powerkit uses it only to narrow down the range of sample sizes to search, and the reported power comes from the simulation in power_interaction(). | E9 |
| k.x1 / k.x2 = 2 | Settings that tell InteractionPoweR's simulation to give x1 or x2 only two possible values, so it becomes a yes/no variable. | E15 |
| rbinary_rs() (x_fun) | Tells power4mome to generate X as a yes/no variable (0 or 1, with a chosen chance of 1) instead of from a normal distribution; the 0/1 values are then rescaled to a chosen mean and standard deviation. | E16, E17 |
| multilevel or cluster design | A design in which people are grouped (for example, pupils within classes, or patients within doctors), so people in the same group tend to be more alike than people in different groups. | E34, E41 |
| growth curves | Models of how each person's scores change over repeated occasions (their trajectory, for example a straight line up or down), and of the average trajectory across people. | E35 |
| cross-lagged panel | A model for two measures (X and Y) recorded at several time points that estimates how each one predicts the other at the next time point, alongside how stable each is over time. | E35 |
| experience sampling | An intensive longitudinal design in which participants answer a questionnaire each time they are prompted (a 'beep'), several times within a day. | E35 |
| CFA | Confirmatory factor analysis: a model in which answers to many questionnaire items are explained by fewer underlying, unobserved traits (factors) that you specify. | E37 |
| SEM and model fit | Structural equation modelling: a family of models that combines regressions among variables with unobserved (latent) variables measured by several items; model fit is how closely the relationships the model implies match those in the data. | E37 |
| measurement invariance | Whether a questionnaire measures the same underlying trait in the same way in different groups (or on different occasions), checked by requiring parts of the measurement model, such as item loadings, to be equal across them. | E37 |
| equivalence test (TOST) | A test that aims to show there is no meaningful effect: two one-sided tests (TOST) check that the effect lies above the lower equivalence bound and below the upper one. | E36 |
| precision planning | Choosing the sample size so that the confidence interval around the estimate is expected to come out no wider than a target width. | E46 |
| Bayes factor | A ratio that says how strongly the data support one hypothesis compared with a competing one (often 'no effect'), used instead of a p-value. | E-bayes |

