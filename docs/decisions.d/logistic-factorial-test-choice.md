## 2026-11-22 · The factorial logistic regression asks which test will be run

The factorial logistic regression card (E47) offers three tests of the
same effect: Firth's penalised likelihood-ratio test (logistf), the
likelihood-ratio test and the Wald test. None is preselected. They test
the same hypothesis and differ in how the p-value is worked out, so the
power should be for the one the researcher will run, and the form says
when each fits. Firth's test was added because, with few events, the
likelihood-ratio test runs above alpha and the Wald test loses power,
while Firth's test kept false positives near alpha and kept the power
(docs/conventions.md, "Choices each card makes for the researcher"). This
replaces the same day's preselection of the likelihood-ratio test.
