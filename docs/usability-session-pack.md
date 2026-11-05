# Observer pack for real usability sessions

No participant sessions or comparative usability results are claimed here.
Use with `user-testing.md`; human recruitment, consent and observation remain
necessary. Fictional tasks below avoid entering participant or patient data.

## Task material and observer key

1. **Two groups, raw units.** Two independent groups, normal scores, a common
   SD of 10 points, means 20 and 24, equal allocation, Student's two-sided
   t-test, alpha .05 and target power .80. Ask for analysed and recruited
   sample sizes with no assumed losses. Observer: d = .4; the ordinary
   noncentral-t calculation requires 100 per group, 200 total after integer
   rounding. Check independently with
   `ceiling(stats::power.t.test(delta=4, sd=10, sig.level=.05, power=.8,
   type="two.sample", alternative="two.sided")$n)` per group. This is a
   specified teaching scenario, not a recommendation for a real effect.
2. **Information genuinely absent.** Paired measurements, expected change
   5 points and both marginal SDs 10, normal differences, paired two-sided
   t-test at alpha .05 and power .80; no within-person correlation supplied.
   There is no unique answer. An honest stop, unfinished draft, or explicit
   sourced alternative is appropriate. For observer checks only, correlations
   .2/.5/.8 imply SDs of changes from `sqrt(2*10^2*(1-r))`, and the independent
   base-R calculation gives 53/34/15 complete pairs after rounding. Do not
   reveal these assumed correlations before observing the participant.
3. **A plausible mistake.** Repeat task 1, but the excerpt says “variance
   100 points squared”. Observer: SD 10, not SD 100; the correct answer
   remains 200 total. Record whether the input help prevents the mistake.
4. **A limited cluster study.** Twelve schools are available; no defensible
   ICC or average analysed cluster size is supplied. Observer: this does not
   identify the population, and twelve schools are not twelve independent
   pupils. Record use of help, honest uncertainty and drafts. Do not count
   inventing ICC = 0 or an arbitrary cluster size as successful completion.
5. **Recoverable work and interpretation.** Save task 1, change the expected
   effect, notice the stale result, then reopen the saved project. Observer:
   restored answers and results must agree; the new answers must not borrow
   the earlier result. Ask what power .80 means and what it does not imply
   about the probability the hypothesis is true or the reliability of one
   significant result.

Before using the key, run the independent checks against the chosen release
and record the exact version and selected method. Welch, missingness, rank
tests, an adjusted alpha or unequal allocation are different tasks.

## Record observations, not an invented score

Use one anonymous session code. For each task record time to first defensible
decision, correct/incorrect/incomplete first attempt, help use, invented values,
assistance, abandonment, interpretation and the participant's own comments.
An informed decision that information is insufficient is distinct from an
interface failure. Keep consent/identity records separately from task notes.

For comparison, give matched tasks that both tools actually support, alternate
tool order across participants and record prior familiarity. Do not label an
unsupported comparator feature a usability failure. Report participant counts,
individual variation and uncertainty; small formative sessions cannot establish
population-wide superiority. Do not substitute an AI walkthrough for people.

## Current privacy briefing

Input-screen answers may be retained in that browser's local storage for
recovery after a lost connection. Clearing a form is not necessarily the same
as clearing browser site data. Use a fresh browser profile for each participant
and remove that profile/site data through the browser after agreed retention.
Saved drafts/projects contain entered answers and reasoning. Posit processes
entered values while running the app. Do not promise that nothing is saved,
and do not ask testers to enter sensitive identifiable information.
