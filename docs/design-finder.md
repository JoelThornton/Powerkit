# Design finder: question tree

The design finder is the simple route on the app's first screen (build guide,
section 7). It helps users who don't yet know the name of their design reach
the right design form. It asks a few questions, each answered by clicking a
plain-language card. This document gives, for every question and every
option:

- the wording the user sees (a card title and a short line of help);
- a **Not sure?** explanation with an example from psychology;
- where the answer leads: the next question, or a design and template in
  `engine/inst/schema/design.schema.json`.

This is a specification for the app (build phase 5). It is not built yet.

## Rules the finder follows

- **Deterministic.** The same answers always lead to the same form. There is
  no AI in the finder; the optional assistant (build phase 7) may fill in the
  same answers from a description, and the user still sees and confirms them.
- **Every answer can be changed.** The path so far is shown as a row of chips
  (e.g. "Different people · Score · Effect depends on W"); clicking a chip
  goes back to that question with the other answers kept where they still
  apply.
- **"Not sure" is always an option.** It opens the question's explanation and
  examples. It never guesses an answer.
- **The finder ends on one design form** and names the analysis in standard
  terms (e.g. "This is a 2 x 2 mixed ANOVA; the test of interest is the
  interaction") so users learn the vocabulary.
- **Shortcut.** "I already know my analysis" skips the questions (see the
  last section).
- **Contested choices are asked, never made silently.** Where the choice of
  analysis is contested, the finder asks the user which analysis they plan,
  explains the trade-off, and the write-up states the choice (see Decisions,
  P1). Paths whose routing has not been decided yet are marked **Open
  question** and route nowhere until the maintainer decides. There are none
  at present.

## Status labels

Each end point carries one of these labels, shown to the user on the final
card.

| Label | Meaning | What the user sees |
| --- | --- | --- |
| **Available** | The engine runs this design today. | The design form. |
| **Coming later (spec ready)** | The design is in the spec format; its engine is being built (build phase 3). | "This design is coming soon. You can fill in the form and save the spec, but you can't run it yet." |
| **Coming later (not in spec)** | Planned (build guide section 2) but not yet in the spec format. | "powerkit doesn't cover this design yet. It is planned for a later version." plus the analysis name, so they can look for another tool. |
| **Open question** | Which analysis to route to is a methodological decision still to be made (see the end of this document). | Not shown to users until decided. |

Today only `factorial_anova / 2x2_between` and `factorial_anova / 2x2_mixed`
are **Available**.

## Overview

```mermaid
flowchart TD
  Q1{Q1 What do you want to show?}
  Q1 -->|A difference| Q2D[Q2 Outcome] --> Q3D[Q3 Who gives the data] --> F[Difference details: F1-F6]
  Q1 -->|A relationship| Q2R[Q2 Outcome] --> Q3R[Q3 Who gives the data] --> R[Relationship details: R1]
  Q1 -->|Works through something| Q2M[Q2 Outcome] --> Q3M[Q3 Who gives the data] --> ME[Mediation details: ME1-ME4]
  Q1 -->|Depends on something| Q2O[Q2 Outcome] --> Q3O[Q3 Who gives the data] --> MO[Moderation details: MO1-MO3]
  Q1 -->|Both| Q2B[Q2 Outcome] --> Q3B[Q3 Who gives the data] --> MM[Moderated mediation details: MM1-MM4]
  Q1 -->|Effect is absent| EQ[Coming later: equivalence]
  Q1 -->|Model fits| SEM[Coming later: SEM / CFA]
```

---

## Q1. What do you want your study to show?

Help line: *Pick the sentence closest to your main hypothesis. You can change
it later.*

**G1. A difference between groups or conditions** *(picture: two bars of
different heights)*
Not sure? Choose this if you compare groups of people, or the same people
under different conditions, on an outcome. Example: *do students who sleep
eight hours recall more words than students who sleep five hours?*
→ Q2 (outcome), then Q3, then the difference details (F1).

**G2. A relationship between two things you measure** *(picture: a scatter
plot with an upward trend)*
Not sure? Choose this if you didn't assign people to conditions, but measured
two variables and expect them to go together. Example: *is daily screen time
related to loneliness?*
→ Q2, then Q3, then R1.

**G3. That an effect works through something else** *(picture: X → M → Y)*
Not sure? This is **mediation**: X affects Y because it changes something in
between (M). Example: *a self-affirmation task reduces defensiveness, which in
turn makes people more willing to change their behaviour.*
→ Q2, then Q3, then ME1.

**G4. That an effect depends on something else** *(picture: two lines with
different slopes)*
Not sure? This is **moderation**, also called an **interaction**: the effect
of X on Y is stronger, weaker or reversed depending on a third variable (W).
Example: *daily stress harms sleep less for people with more social support.*
→ Q2, then Q3, then MO1.

**G5. Both: an effect that works through something else, and part of that
depends on something else** *(picture: X → M → Y with W pointing at one
arrow)*
Not sure? This is **moderated mediation**. Example: *a threat manipulation
raises perceived threat, which raises support for a policy, but the first
step happens mainly for people who identify strongly with their group.*
→ Q2, then Q3, then MM1.

**G6. That an effect is absent, or too small to matter** *(picture: a
narrow band around zero)*
Not sure? Choose this if your hypothesis is that two things are **the same**,
within a margin you care about. A non-significant result is not evidence of
no effect; you need an equivalence test. Example: *a 5-item short form gives
the same scores as the 20-item original, within ±0.2 SD.*
→ **Coming later (not in spec):** equivalence test (TOST) or minimum-effect
test.

**G7. That a model or questionnaire structure fits the data** *(picture: a
small path diagram with latent circles)*
Not sure? Choose this if your aim is to check a measurement model or a
structural equation model rather than one effect. Example: *checking that a
new wellbeing scale has the three factors it was designed to have.*
→ **Coming later (not in spec):** CFA / SEM model fit (e.g. RMSEA).

**Not sure** — *Think of the sentence you would write as Hypothesis 1 in a
preregistration. "Group A will score higher than group B" is a difference;
"X will be related to Y" is a relationship; "X will affect Y through M" is
mediation; "the effect of X on Y will be stronger when W is high" is
moderation. If none fits, use "Build my own model".*

---

## Q2. What is your outcome like?

Help line: *The outcome is what you measure to see whether your hypothesis
holds (your dependent variable).*

**O1. A score or scale** *(picture: a ruler)*
Not sure? A number where higher means more of something: a questionnaire
total or average, a reaction time, words recalled out of 20, a 0–100 slider.
Example: *the mean of a 10-item anxiety scale.*
→ Continue to Q3.

**O2. Yes or no** *(picture: a tick and a cross)*
Not sure? Each person ends up in one of two categories. Example: *did the
participant attend the follow-up session? Did they choose the healthy snack?*
→ G1 or G2: continue to Q3.
→ G3, G4 or G5: **Coming later (not in spec):** mediation and moderation with
a yes/no outcome (logistic models).

**O3. One of several categories** *(picture: three labelled boxes)*
Not sure? Each person ends up in one of three or more categories with no
order. Example: *attachment style: secure, anxious or avoidant.*
→ G1 or G2: continue to Q3.
→ G3, G4 or G5: **Coming later (not in spec).**

*(This option is not in the guide's list for Q2; it is needed to reach the
chi-square test of independence.)*

**O4. A count** *(picture: tally marks)*
Not sure? How many times something happened, with no fixed maximum. Example:
*cigarettes smoked last week; intrusive thoughts recorded in a day.*
→ **Coming later (not in spec):** Poisson or negative binomial models.

**O5. A rating on a few points** *(picture: five radio buttons)*
Not sure? A single question answered on a short scale, such as 1 to 5 from
"strongly disagree" to "strongly agree". If you average several such items
into a scale score, choose "A score or scale" instead.
→ O5a.

### O5a. How will you analyse this rating? *(after O5; decision D1)*

Help line: *Researchers disagree about this, so we ask rather than choose for
you. Your answer is stated in the write-up.*

**As a score (for example, comparing mean ratings)** *(picture: a ruler)*
Not sure? You will compare averages, as in a t-test or ANOVA. Example:
*mean agreement (1–7) with "I feel calm" after mindfulness vs control.*
→ Continue as O1 (score), with this note on the final card and in the
write-up: *"This treats the rating as an interval scale: the step from 1 to 2
counts the same as the step from 4 to 5. This is debated. Some
methodologists consider it a reasonable approximation for means; others
argue that for single items it can give misleading results and recommend
ordinal models."*

**As ordered categories** *(picture: a staircase)*
Not sure? You will treat the answers as ordered categories without assuming
equal steps, for example with an ordinal (cumulative link) regression.
Example: *the proportion choosing each level of "How often do you feel
lonely?" (never, rarely, sometimes, often).*
→ **Coming later (not in spec):** ordinal models.

The finder applies no automatic cut-off by number of points (e.g. it does not
treat 7-point items as scores and 5-point items as ordinal).

**Not sure** — *Look at one participant's data for your outcome. Is it a
number that can take many values (score), one of two answers (yes/no), one
of several labels (categories), how many times something happened (count),
or one answer on a short rating scale (rating)?*

---

## Q3. Who gives the data?

Help line: *How participants relate to your conditions or measurements.*

For G2 (a relationship) the first option reads: **"Each person is measured
once, on both variables."** For all other goals the options are as below.

**P1. Different people in each group or condition** *(picture: two separate
groups of figures)*
Not sure? Each person takes part in only one condition, or belongs to only
one group. Example: *half the participants do the training and half don't.*
→ Continue to the details for the chosen goal.

**P2. The same people in every condition** *(picture: one group of figures
with arrows to each condition)*
Not sure? Each person does every condition, usually in a counterbalanced
order. Example: *everyone rates faces both under time pressure and without
it.*
→ G1: continue to F1.
→ G2, G3, G4, G5: **Coming later (not in spec):** within-person correlation,
mediation and moderation (multilevel models).

**P3. People respond to many items or stimuli** *(picture: one person facing
a grid of pictures)*
Not sure? Each person reacts to many stimuli (words, faces, vignettes) and you
want your conclusion to hold for other stimuli like these, not just the ones
you used. Example: *a lexical decision task with 80 words.*
→ **Coming later (not in spec):** mixed-effects models with crossed
participants and stimuli (decision D3). The final card explains: *"Averaging
each person's responses over the stimuli and running a t-test or ANOVA
treats your particular stimuli as the only ones that matter. If you want to
generalise to other stimuli, the variability between stimuli has to be in
the model; leaving it out overstates power, sometimes by a lot."*

**P4. People are nested in groups (classes, teams, clinics)** *(picture:
figures inside circles)*
Not sure? Participants come in clusters that share something, so people in
the same cluster tend to be more alike. Example: *pupils in 20 classrooms,
with whole classrooms assigned to the intervention.*
→ **Coming later (not in spec):** multilevel models (decision D4). The
final card explains that ignoring clustering overstates power. A
design-effect approximation (inflating a single-level sample size by
1 + (m − 1) × ICC, where m is the cluster size and ICC the intraclass
correlation) is a legitimate option that may be added later, clearly
labelled as an approximation.

**P5. The same people measured over time** *(picture: one figure on a
timeline)*
Not sure? You measure each person on several occasions. Example: *depression
before and after therapy; a daily diary kept for two weeks.*
→ Ask T1.

**Not sure** — *Ask yourself: could one participant appear in more than one of
your conditions? If no, choose "Different people". If yes, choose "The same
people". If your participants come in groups (classes, couples, teams) or
each respond to many stimuli, choose the option that describes that.*

### T1. How many times is each person measured? *(after P5)*

**Twice (for example, before and after)** *(picture: two dots on a
timeline)*
Not sure? Example: *anxiety measured at the start and at the end of an
8-week course.*
→ Treated as a within-person factor "Time" with two levels, then F1.
One group measured twice leads to the paired t-test (F2). Groups measured
before and after lead to the pre–post questions (PP1, PP2; decision D2).

**Three or more times** *(picture: several dots on a timeline)*
Not sure? Example: *mood measured weekly for 10 weeks; experience sampling
five times a day.*
→ **Coming later (not in spec):** growth curve, cross-lagged panel or
intensive longitudinal models.

---

## Difference details (G1)

### F1. How many things did you vary or compare?

Help line: *Each thing you vary is called a factor (for example "condition"
or "time").*

**One** *(picture: one row of bars)*
Not sure? A single manipulation or grouping. Example: *training vs no
training.*
→ F2.

**Two, crossed** *(picture: a 2 x 2 grid)*
Not sure? Two factors where every combination appears. Example: *feedback
(none vs praise) crossed with task difficulty (easy vs hard), giving four
combinations.*
→ Score outcome (O1): F3.
→ Yes/no or categories (O2, O3): **Coming later (not in spec):** logistic or
log-linear models for two factors.

**Three or more** *(picture: a cube)*
Not sure? Example: *feedback x difficulty x age group.*
→ **Coming later (not in spec):** 2 x 2 x 2 and larger factorial designs.

### F2. How many groups or conditions? *(one factor)*

**One group, compared with a fixed value** *(picture: one bar and a dashed
line)*
Not sure? You have one group and compare its average with a known number.
Example: *is mean mood above the scale midpoint of 4? Is accuracy above
chance (50%)?*
→ O1 score: `basic_test / one_sample_t` — **Coming later (spec ready).**
Analysis name: *one-sample t-test.*
→ O2 yes/no: **Coming later (not in spec):** test of one proportion.

**Two** *(picture: two bars)*
Not sure? Example: *intervention vs control; morning vs evening testing.*
→ See the table below.

**Three or more** *(picture: three bars)*
Not sure? Example: *three types of feedback: none, praise, criticism.*
→ Score outcome (O1): F2a. Other outcomes: see the table below.

| Outcome | Who gives the data | Two groups / conditions | Three or more |
| --- | --- | --- | --- |
| O1 Score | P1 Different people | `basic_test / independent_t`, **Coming later (spec ready)**; *independent-samples t-test*; Student's by default, Welch's as an option (decision D7) | F2a |
| O1 Score | P2 Same people, or P5 measured twice | `basic_test / paired_t`, **Coming later (spec ready)**; *paired-samples t-test* (one group measured twice, decision D2) | F2a |
| O2 Yes/no | P1 Different people | `basic_test / two_proportions`, **Coming later (spec ready)**; *test of two proportions (z test)* | `basic_test / chi_square_independence`, **Coming later (spec ready)**; *chi-square test of independence* |
| O2 Yes/no | P2 or P5 | **Coming later (not in spec):** *McNemar's test* | **Coming later (not in spec):** *Cochran's Q* |
| O3 Categories | P1 Different people | `basic_test / chi_square_independence`, **Coming later (spec ready)** | `basic_test / chi_square_independence`, **Coming later (spec ready)** |
| O3 Categories | P2 or P5 | **Coming later (not in spec)** | **Coming later (not in spec)** |

On the independent-samples t-test form, Student's t-test (equal variances
assumed) is pre-selected, matching G*Power; Welch's t-test is offered as an
option. The write-up names the test used (decision D7).

### F2a. What does your hypothesis say about the groups? *(three or more groups, score outcome; decision D8)*

Help line: *Researchers disagree about whether to power the overall test or a
specific comparison, so we ask. Your answer is stated in the write-up.*

**A specific comparison** *(picture: two of three bars highlighted)*
Not sure? Your hypothesis names which groups differ, or in what pattern.
Example: *both feedback conditions will outperform no feedback.*
→ **Coming later (not in spec):** planned contrast (for different people,
or for the same people in every condition). The final card notes: *"A
planned contrast must be specified in your preregistration before you see
the data. Choosing it afterwards invalidates the test."*

**Any difference among the groups** *(picture: three bars, none
highlighted)*
Not sure? Your hypothesis is only that the groups are not all equal.
Example: *the three feedback types will differ in persistence.*
→ **Coming later (not in spec):** omnibus *one-way ANOVA* (different people)
or *repeated-measures ANOVA* (same people).

### F3. Does each factor have exactly two levels? *(two factors, score outcome)*

**Yes: 2 x 2** *(picture: a 2 x 2 grid)*
Not sure? Each factor has two versions. Example: *praise vs none, and easy vs
hard.*
→ F4.

**No: at least one factor has three or more** *(picture: a 2 x 3 grid)*
Not sure? Example: *three feedback types crossed with easy vs hard.*
→ **Coming later (not in spec):** larger factorial ANOVA.

### F4. For each factor: did different people get each level, or did everyone get both?

Help line: *Answer once for each factor. Example: "Group: different people;
Time: everyone at both."*

For each factor the options are **Different people** (between participants)
and **Everyone got both** (within participants), with this Not sure?: *If one
person could appear at both levels of this factor, choose "Everyone got
both". Example: in a study of therapy vs waitlist measured before and after,
"therapy vs waitlist" is different people and "before vs after" is everyone
got both.*

| Factor A | Factor B | Next |
| --- | --- | --- |
| Different people | Different people | F4a, then (equal groups) `2x2_between` |
| Different people | Everyone got both | F4a, then (equal groups) F4b |
| Everyone got both | Different people | As the row above, with the factors swapped so that A is the between factor (the spec's convention) |
| Everyone got both | Everyone got both | **Coming later (not in spec):** *2 x 2 within-participants ANOVA* |

### F4a. Will the groups be equal in size? *(at least one factor between; decisions D5, N1, N2 and N3)*

Help line: *What matters is whether every group (every combination, if both
factors are between participants) will have the same number of people, not
whether you assigned the factor or measured it.*

**Yes: the same number in every group** *(picture: a grid with equal dots)*
Not sure? Choose this if you assign people to the groups with equal numbers,
or recruit a fixed, equal number into each group. Examples: *praise vs none,
crossed with easy vs hard, randomised with 30 people per combination;
recruiting exactly 50 patients and 50 controls, each tested in two
conditions.*
→ Both factors between: `factorial_anova / 2x2_between`, **Available**.
Analysis name: *2 x 2 between-participants ANOVA.* Then F5.
→ One factor within: F4b.

**No: the groups will differ in size** *(picture: a grid with unequal dots)*
Not sure? Choose this if you expect different numbers in the groups, for
example because you record a characteristic of whoever takes part rather than
recruiting fixed numbers. Examples: *a manipulation crossed with the gender
of whoever signs up; more patients than controls.*
→ **Coming later (not in spec):** *2 x 2 between-participants ANOVA with
unequal group sizes* or *2 x 2 mixed ANOVA with unequal group sizes*, for any
effect (main effect or interaction), until validated (decision N3). The card
says: *"powerkit doesn't cover unequal group sizes in 2 x 2 designs yet."* For a main effect, powerkit does
not offer a simpler test that ignores the other factor (such as an
independent-samples t-test) as a stand-in (decision N2).

### F4b. Is the within-participants factor a "before and after" measurement? *(one factor between, one within, equal groups)*

**Yes: before and after** *(picture: two dots on a timeline)*
Not sure? Everyone is measured before and after something, and the groups
differ in what happens in between. Example: *therapy vs waitlist, anxiety
measured before and after.*
→ PP1.

**No: another within-participants condition** *(picture: one person, two
conditions)*
Not sure? Example: *each person rates faces with and without time pressure;
the groups are two training conditions.*
→ `factorial_anova / 2x2_mixed`, **Available**. Analysis name: *2 x 2 mixed
ANOVA.* Then F5. (Only reached with equal group sizes; see F4a and decision
N1.)

### PP1. Were people randomly assigned to the groups? *(pre–post with two groups; decision D2)*

**Yes, randomly assigned** *(picture: a die)*
Not sure? Example: *a randomised controlled trial of therapy vs waitlist.*
→ PP2, with this note: *"With randomised groups, ANCOVA (the after score
adjusted for the before score) is usually more powerful than the 2 x 2 mixed
interaction, so it often needs fewer participants."*

**No, the groups already existed or chose themselves** *(picture: two
labelled groups)*
Not sure? Example: *students who signed up for a course vs students who
didn't; two schools.*
→ PP2, with this note: *"Without random assignment, ANCOVA and the mixed
interaction (equivalent to comparing change scores) can answer different
questions and can give different answers from the same data (Lord's
paradox). Neither is right by default; choose the analysis that matches your
research question and explain the choice."* No option is recommended.

### PP2. Which analysis do you plan to use?

Help line: *Researchers disagree about this, so we ask rather than choose for
you. Your answer is stated in the write-up.*

**ANCOVA: the after score, adjusting for the before score** *(picture: an
arrow from "before" to "after")*
Not sure? Example: *comparing post-therapy anxiety between groups,
controlling for baseline anxiety.*
→ **Coming later (not in spec):** *ANCOVA.*

**The 2 x 2 mixed ANOVA interaction** *(picture: a 2 x 2 grid, group x
time)*
Not sure? Example: *testing whether anxiety changes more from before to after
in the therapy group than in the waitlist group.*
→ `factorial_anova / 2x2_mixed` with the group as factor A (between) and time
as factor B (within), `effect = interaction`, **Available**. Analysis name:
*2 x 2 mixed ANOVA (group x time interaction).* F5 is not asked; then F6.

### F5. Which result matters most for your study?

Help line: *Power is calculated for one effect. Choose the one your main
hypothesis is about.* (The options use the user's own factor names.)

**"The effect of [Factor A], averaged over [Factor B]"** → `target_test.effect
= main_effect_A`
Not sure? You expect Factor A to matter regardless of B. Example: *praise
improves persistence on both easy and hard tasks.*

**"The effect of [Factor B], averaged over [Factor A]"** → `main_effect_B`
Not sure? As above, for Factor B.

**"Whether the effect of one depends on the other"** → `interaction`, then F6
Not sure? You expect the effect of one factor to be different at the two
levels of the other. Example: *praise helps on hard tasks but not on easy
ones.* In a pre–post study with a control group, the hypothesis "the therapy
group improves more than the waitlist group" is this one.

### F6. Which picture matches your prediction? *(interaction only)*

Help line: *Each picture shows the outcome for the four combinations. Pick the
shape you expect; you will enter the actual numbers on the next screen.*

**The lines cross** *(picture: an X)*
Not sure? The effect reverses: it goes one way at one level and the other way
at the other. Example: *praise helps on hard tasks but hurts on easy ones.*

**One effect shrinks** *(picture: two lines that converge but don't meet)*
Not sure? The effect is there at both levels but smaller at one. Example:
*praise helps a lot on hard tasks and a little on easy ones.*

**One effect disappears** *(picture: one flat line and one sloped line)*
Not sure? The effect is present at one level and absent at the other.
Example: *praise helps on hard tasks and makes no difference on easy ones.*

First, the finder asks **"Whose effect changes?"** with the two factors as
options (e.g. *"the effect of difficulty, at each level of feedback"*). The
shape depends on which factor's effect is drawn: means of 0 and 2 for A1 and
0 and 1 for A2 show B's effect shrinking but A's effect disappearing.

The picture records the expected shape only (decision D6). It does not
pre-fill any cell means: the user enters all four means on the form and
justifies them. All three shapes lead to the same form (2 x 2 between or
mixed, as chosen above).

**Shape check.** When the means are entered, the form compares them with the
chosen shape using the two simple effects of the chosen factor (its effect at
each level of the other factor), and shows a warning, not an error, if they
don't match:

| Chosen shape | The entered means match if | Warning if not |
| --- | --- | --- |
| The lines cross | the two simple effects have opposite signs | *"Your means don't show a reversal: the effect of [factor] goes the same way at both levels of [other factor]."* |
| One effect shrinks | the simple effects have the same sign, are both non-zero, and differ in size | *"Your means don't show a shrinking effect: [describe what they show]."* |
| One effect disappears | one simple effect is exactly zero and the other is not | *"Your means don't show an effect that disappears: neither simple effect is zero."* |

---

## Relationship details (G2)

### R1. What is the other variable like?

Help line: *Your outcome is [outcome type from Q2]. What is the variable you
expect it to be related to?*

**A score or scale** *(picture: a ruler)*
Not sure? Example: *screen time in hours per day.*
→ O1 score outcome, P1: `basic_test / correlation`, **Coming later (spec
ready)**. Analysis name: *Pearson correlation.*
→ O2 yes/no outcome: **Coming later (not in spec):** *logistic regression.*
→ O3 categories outcome: **Coming later (not in spec).**

**Groups or categories** *(picture: labelled boxes)*
Not sure? Example: *smokers vs non-smokers; attachment style.*
→ O1 score outcome: this is a comparison between groups. The finder says
*"A score compared across groups is a difference between groups; we've moved
you to that path"* and goes to F1 with Q2 and Q3 kept.
→ O2 or O3 outcome, P1: `basic_test / chi_square_independence`, **Coming
later (spec ready).** Analysis name: *chi-square test of independence.*

**Several predictors at once, or controlling for other variables** *(picture:
several arrows into one box)*
Not sure? Example: *does screen time predict loneliness after accounting for
age and social anxiety?*
→ **Coming later (not in spec):** *multiple regression.*

For G2, any answer other than P1 at Q3 leads to **Coming later (not in
spec)** (within-person or multilevel correlation).

---

## Moderation details (G4)

*Requires O1 (score outcome); other outcomes are coming later (see Q2).*

### MO1. What is your main predictor (X)?

**Conditions you assigned, with two levels** *(picture: two boxes with an
arrow from a die)*
Not sure? You randomly assigned people to one of two conditions. Example:
*mindfulness exercise vs reading a text.*

**Two groups that already exist** *(picture: two labelled groups)*
Not sure? A grouping you didn't assign. Example: *smokers vs non-smokers.*

**A measured score** *(picture: a ruler)*
Not sure? Example: *daily stress measured with a questionnaire.*

**Three or more conditions or groups** *(picture: three boxes)*
→ **Coming later (not in spec).**

### MO2. What does the effect depend on (the moderator, W)?

**Two conditions you assigned** *(picture: two boxes with a die)*
Not sure? You assign people to these too. Example: *easy vs hard task.*

**Two groups that already exist** *(picture: two labelled groups)*
Not sure? A characteristic you record. Example: *men vs women; clinical vs
non-clinical sample.*

**A measured score** *(picture: a ruler)*
Not sure? Example: *social support; trait anxiety.*

**Three or more groups** *(picture: three boxes)*
→ **Coming later (not in spec).**

### MO3. Does a third variable change the interaction again?

**No** → see the mapping below.
**Yes (a three-way interaction)** → **Coming later (not in spec).**
Not sure? Example of a three-way interaction: *praise helps on hard tasks,
but only for children, not adults.*

| X (MO1) | W (MO2) | Who gives the data (Q3) | Leads to | Status | Analysis name shown |
| --- | --- | --- | --- | --- | --- |
| Two levels (assigned or existing) | Two groups or conditions (assigned or existing) | P1, or one factor within | F4, then F4a, with `effect = interaction`. Equal group sizes: `factorial_anova / 2x2_between` or `2x2_mixed` (F4b). Unequal group sizes: coming later (decisions D5 and N1) | **Available** (equal groups); **Coming later (not in spec)** (unequal groups) | *2 x 2 ANOVA interaction*, or *2 x 2 ANOVA with unequal group sizes* |
| Two levels | A score | P1 | `regression_interaction / two_way` (X binary, W continuous) | **Coming later (spec ready)** | *moderated regression (continuous x binary interaction)* |
| A score | Two groups | P1 | `regression_interaction / two_way` (X continuous, W binary) | **Coming later (spec ready)** | *moderated regression (continuous x binary interaction)* |
| A score | A score | P1 | `regression_interaction / two_way` (both continuous) | **Coming later (spec ready)** | *moderated regression (continuous x continuous interaction)* |
| Any | Any | P2, P3, P4, P5 (except 2 x 2 mixed above) | | **Coming later (not in spec)** | *multilevel moderation* |

---

## Mediation details (G3)

*Requires O1 (score outcome) and P1 at Q3 (each person measured once, or
measured at several times but analysed person by person). Repeated-measures
and multilevel mediation are **Coming later (not in spec).***

### ME1. What is the cause (X)?

**Conditions you assigned** *(picture: two boxes with a die)*
Not sure? Example: *self-affirmation vs control task.*

**A measured score** *(picture: a ruler)*
Not sure? Example: *workload measured with a questionnaire.*

Both lead to ME2. (The spec allows X to be binary or continuous.)

Notes on the final card and in the write-up (decision D9), stated neutrally:

- If X is measured: *"X was measured rather than manipulated, so the X → M
  and X → Y paths are associations, not effects of an experimental
  manipulation."*
- Always: *"The M → Y path is not randomised, even when X is manipulated,
  because participants are not assigned to levels of M."*

### ME2. How many go-betweens (mediators)?

**One** *(picture: X → M → Y)*
Not sure? Example: *workload → exhaustion → intention to quit.*
→ ME4, then `mediation / process_4` with a single mediator `M`. Analysis
name: *simple mediation (PROCESS model 4).*

**Two or more** *(picture: X with two arrows)*
→ ME3.

### ME3. How do the mediators connect?

**Side by side: X affects each one separately** *(picture: X → M1 → Y and X →
M2 → Y)*
Not sure? Example: *workload raises both exhaustion and cynicism, and each
raises intention to quit.*
→ ME4, then `mediation / process_4` with mediators `M1`, `M2`, ... (up to 9).
Analysis name: *parallel mediation (PROCESS model 4).*

**In a chain: X affects the first, which affects the next** *(picture: X → M1
→ M2 → Y)*
Not sure? Example: *a growth-mindset intervention changes beliefs, which
increases effort, which raises grades.*
→ ME4, then `mediation / process_6` (2 to 4 mediators; more is **Coming later
(not in spec)**). Analysis name: *serial mediation (PROCESS model 6).*

### ME4. Are your mediators scores?

**Yes** → the form for the template chosen in ME2 or ME3: **Coming later
(spec ready).**
**No, at least one is yes/no or a category** → **Coming later (not in spec).**
Not sure? A mediator is a score if it is a number that can take many values,
like a questionnaire mean.

The final screen also asks which indirect path the power analysis is for (the
spec's `target_test.path`, e.g. "X → M1 → M2 → Y"). That is part of the form,
not the finder.

---

## Moderated mediation details (G5)

*Requires O1 (score outcome) and P1 at Q3, as for mediation.*

### MM1. What is the cause (X)?

As ME1.

### MM2. What does part of the process depend on (the moderator, W)?

As MO2: **Two groups or conditions** or **A measured score** (the spec allows
W to be binary or continuous). Three or more groups → **Coming later (not in
spec).**

### MM3. How many mediators?

**One** → MM4.
**Two or more** → **Coming later (not in spec).**

### MM4. Which link depends on W?

**The link from X to the mediator** *(picture: W pointing at the X → M
arrow)*
Not sure? Example: *the threat manipulation raises perceived threat more for
people who identify strongly with their group.*
→ `moderated_mediation / process_7`, **Coming later (spec ready).** Analysis
name: *first-stage moderated mediation (PROCESS model 7); test of the index
of moderated mediation.*

**The link from the mediator to the outcome** *(picture: W pointing at the M →
Y arrow)*
Not sure? Example: *emotional exhaustion lowers job performance less for
people with high coping self-efficacy.*
→ `moderated_mediation / process_14`, **Coming later (spec ready).**
Analysis name: *second-stage moderated mediation (PROCESS model 14); test of
the index of moderated mediation.*

**Both links** *(picture: W pointing at both arrows)*
→ **Coming later (not in spec):** PROCESS model 58.

**The link from X to the mediator, and the direct link from X to the
outcome** *(picture: W pointing at X → M and X → Y)*
→ **Coming later (not in spec):** PROCESS model 8 (all three links: model
59).

**Not sure** — *Ask which part of your explanation you expect to be stronger
for some people. If W changes how much X moves the mediator, it is the first
link; if W changes how much the mediator matters for the outcome, it is the
second.*

---

## "I already know my analysis" (shortcut)

A searchable list. Choosing an entry opens its form directly and shows the
same status label.

| Listed as | Leads to | Status |
| --- | --- | --- |
| One-sample t-test | `basic_test / one_sample_t` | Coming later (spec ready) |
| Independent-samples t-test (Student's by default; Welch's as an option) | `basic_test / independent_t` | Coming later (spec ready) |
| Paired-samples t-test | `basic_test / paired_t` | Coming later (spec ready) |
| Pearson correlation | `basic_test / correlation` | Coming later (spec ready) |
| Test of two proportions (z test) | `basic_test / two_proportions` | Coming later (spec ready) |
| Chi-square test of independence | `basic_test / chi_square_independence` | Coming later (spec ready) |
| 2 x 2 between-participants ANOVA | `factorial_anova / 2x2_between` | **Available** |
| 2 x 2 mixed ANOVA (one factor between, one within) | `factorial_anova / 2x2_mixed` | **Available** |
| Moderated regression (two-way interaction) | `regression_interaction / two_way` | Coming later (spec ready) |
| Simple mediation (PROCESS model 4) | `mediation / process_4`, one mediator | Coming later (spec ready) |
| Parallel mediation (PROCESS model 4) | `mediation / process_4`, several mediators | Coming later (spec ready) |
| Serial mediation (PROCESS model 6) | `mediation / process_6` | Coming later (spec ready) |
| PROCESS model 7 | `moderated_mediation / process_7` | Coming later (spec ready) |
| PROCESS model 14 | `moderated_mediation / process_14` | Coming later (spec ready) |
| One-way ANOVA; repeated-measures ANOVA; planned contrasts; 2 x 2 within ANOVA; 2 x 2 x 2 ANOVA; ANCOVA | | Coming later (not in spec) |
| Three-way interaction; PROCESS models 8, 58, 59 | | Coming later (not in spec) |
| Equivalence test (TOST); minimum-effect test | | Coming later (not in spec) |
| Logistic, Poisson or ordinal regression; McNemar's test | | Coming later (not in spec) |
| Mixed-effects (participants x stimuli); multilevel models | | Coming later (not in spec) |
| Growth curve, cross-lagged panel, EMA models | | Coming later (not in spec) |
| CFA, SEM, measurement invariance | | Coming later (not in spec) |

---

## Decisions

Decided by the maintainer (to be copied into `docs/decisions.md`). The
routing above follows them.

**P1. Principle: contested choices are asked, never made silently.** Where
the choice of analysis is contested, the finder asks the user which analysis
they plan, explains the trade-off on the card, and the write-up states the
choice. The finder never chooses silently.

**D1. Single rating items (O5 → O5a).** The finder asks whether the item will
be analysed as a score or as ordered categories. *Score* continues on the
score path, with a note that this treats the rating as an interval scale,
which is contested (the debate is summarised on the card). *Ordered
categories* is "coming later" (ordinal models). There is no automatic cut-off
by number of scale points.

**D2. Pre–post designs (T1, F4b, PP1, PP2).** For two groups measured before
and after, the finder asks which analysis is planned: ANCOVA (coming later)
or the 2 x 2 mixed interaction (available). If the groups were randomised,
the card notes that ANCOVA is usually more powerful. If not, the card notes
that the two analyses can answer different questions (Lord's paradox) and
recommends neither. One group measured twice goes to the paired t-test.

**D3. Many items or stimuli (P3).** "Coming later" (mixed-effects models),
with an explanation that averaging over stimuli overstates power when the aim
is to generalise beyond the stimuli used.

**D4. Nested data (P4).** "Coming later" (multilevel models). A design-effect
approximation is a legitimate option to add later, clearly labelled as an
approximation.

**D5. Two binary factors (F4a, F4b, moderation table), as refined by N1.**
Route on whether the group sizes are equal, not on whether a factor is
assigned or measured. Equal groups (assigned, or recruited in fixed equal
numbers) go to the 2 x 2 between or 2 x 2 mixed template. Unequal groups are
"coming later". (This replaces the earlier rule, which sent a measured factor
or unequal groups to the regression interaction template.)

**D6. Interaction shape pictures (F6).** The picture records the expected
shape only; no cell means are pre-filled. The form warns (does not block) if
the entered cell means don't match the chosen shape. Because the shape
depends on whose effect is drawn, the finder first asks which factor's effect
changes.

**D7. Two groups, score outcome (F2).** Student's t-test is the default,
matching G*Power; Welch's t-test is an option. The write-up names the test
used.

**D8. Three or more groups (F2a).** The finder asks whether the hypothesis is
a specific comparison or any difference among the groups, and offers a
planned contrast or the omnibus test accordingly, noting that a contrast must
be preregistered. Both are "coming later".

**D9. Mediation (ME1).** One neutral sentence when X is measured rather than
manipulated, and a note, always shown, that the M → Y path is not randomised.

**N1. Group sizes, not assignment, decide the 2 x 2 route (F4a, F4b,
moderation table).** This refines D5 and applies to both 2 x 2 templates.
Equal groups, whether assigned or recruited in fixed equal numbers, go to
`factorial_anova / 2x2_between` or `factorial_anova / 2x2_mixed`. Unequal
groups go to "coming later".

*Superpower and unequal group sizes (checked with Superpower 0.2.4.1; details
in `docs/conventions.md`, "Superpower and unequal group sizes").*
`ANOVA_design()` accepts unequal `n` without error, but builds its data
balanced at `max(n)`. For a 2 x 2 mixed design (`"2b*2w"`), `ANOVA_exact()`,
`ANOVA_exact2()` and `ANOVA_power()` all stop with an error. For a 2 x 2
between design (`"2b*2b"`), `ANOVA_exact()` stops, but `ANOVA_power()` runs;
whether it uses the unequal sizes correctly has not been validated.

**N2. Main effects with unequal groups (F4a).** A main-effect hypothesis in a
2 x 2 design with unequal groups is "coming later". The finder does not route
it to an approximation, such as an independent-samples t-test that ignores
the other factor.

*To check: whether InteractionPoweR's simulation reports power for the main
effects as well as the interaction* (relevant if it is used for unequal
groups later). InteractionPoweR is not installed in the build environment, so
this has not been checked.

**N3. Unequal groups need independent validation (F4a).** Unequal group
sizes stay "coming later" until they are validated against an independent
reference: a published value, or an exact calculation done independently of
Superpower. That a backend's functions run without error is not enough. Any
unequal-n support must also include a test proving that the unequal sizes are
actually used, not replaced by a balanced design (see `docs/conventions.md`,
"Superpower and unequal group sizes").

**Accepted:** the "One of several categories" outcome option (O3), added to
the guide's list so that the chi-square test of independence can be reached.
