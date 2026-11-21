## 2026-11-21 · Bayes factor tables: simulate the totals the sampling plan fixes

E6's contingency table Bayes factor scored each simulated table with the
sampling plan chosen (JASP's default, "Indep. multinomial, rows fixed")
but drew every table with only the total fixed (2 November 2026), so the
group sizes varied by chance while the analysis assumed they were set in
advance. That understated power: with 15 a group, rates .70 and .30,
prior concentration 1 and a threshold of 10, 36.0% instead of the 43.2%
for the plan the researcher described. When the plan fixes the rows (or
the columns), each simulated study now has those totals, at the table's
row (or column) shares of n in whole people (largest remainder), and each
row (or column) is drawn from its conditional probabilities; the joint
multinomial and Poisson plans keep the fixed total. The option's label
says the totals are set in advance, the gap is larger than the
simulation's error, and no other tool plans this power, so this follows
what the plan describes and is not a departure. Relabelling the option,
or offering only plans that match a fixed total, were the alternatives
considered: the first would knowingly report too little power for the
usual experiment, and the second would drop JASP's default analysis.
