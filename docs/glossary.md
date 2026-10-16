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
| repeated measurements | The same people measured more than once (for example, before and after, or in each condition); their scores on different occasions usually go together. | E8, E18, E20 |
| cell means | The expected average in each combination of the factors, such as praise with a hard task (each combination is a 'cell'). | E7, E8, E20, E21, E22 |
| factor and levels | A factor is something you vary or compare (for example, feedback); its levels are its versions (for example, praise and none). | E7, E8, E47, E-bayes |
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
| regression coefficients | How much the outcome is expected to change for a one-unit change in a predictor. | E27 |
| rate ratio | How many times higher the average count is in one group than in another; 1 means no difference. | E28 |
| product terms | Two predictors multiplied together (for example, x1 times x2), which is how a regression represents an interaction. | E31 |
| fixed effects | The effects you're testing (for example, of a condition), taken to be the same for everyone. | E33 |
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
| model parameters | The numbers that define a model, such as the strength of each path. | E37 |
| prior | The range of effect sizes you consider plausible before seeing the data, written as a distribution. | E-bayes |

