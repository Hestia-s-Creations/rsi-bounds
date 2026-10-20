# Bounds on recursive self-improvement

What can be proved about how fast a self-improving AI gets better, and an experiment designed to test it.

**Result in one line:** a system can out-think its inputs, but it can't out-know them.

- Knowledge of the world grows by at most the bits that come in from outside, and never past memory.
  A closed system learns nothing new about its world.
- Sustained learning with finite memory forces forgetting at the same long-run rate.
- Two minds talking know no more than their combined inputs; they can only exceed each other in skill.
- Compute-only skill follows a growth law set by the returns to research, *r*. Current estimates put *r* on
  both sides of 1, so whether it accelerates is an open empirical question.
- No general theorem can predict the growth of an arbitrary self-improving system: the question is
  undecidable with unbounded memory and PSPACE-complete with bounded memory.

## Contents

| Path | What it is |
|---|---|
| `THEOREM.md` | Seven theorems with proofs (information-theoretic form), worked numbers and sources |
| `checks/check_bounds.py` | Exact numerical checks of every inequality on hundreds of small random systems |
| `lean/SensorExperiment.lean` | Lean 4 + Mathlib. Part A: the counting form of the theorems, machine-checked. Part B: the experiment's hypotheses as exact yes/no checks on the log |
| `EXPERIMENT.md` | Pre-registered plan: do two models stay out of a loop when a sensor feeds them real information? |

## Checking it

```sh
python3 checks/check_bounds.py          # needs numpy and scipy; prints ALL CHECKS PASS

cd lean
lake exe cache get                      # downloads prebuilt Mathlib
lake build                              # no errors, no sorry
```

The Lean proofs use only Lean's standard axioms (`propext`, `Classical.choice`, `Quot.sound`).
They were checked with Lean v4.35.0-rc4 and Mathlib v4.35.0-rc4.

## Status

The theorems and checks are complete. The experiment is designed but has not been run.

Copyright © 2026 Hestia's Creations. Licensed under the GNU General Public License v3.0 or later; see `LICENSE`.
