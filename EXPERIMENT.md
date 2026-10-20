# Sensor experiment: full protocol (pre-registered 2026-10-19, revised 2026-10-19)

This document specifies the experiment in its full form, for a laboratory with the compute to run it.
Hestia's Creations designed it and has not run it. A reduced version for our own hardware (one 8B model,
5 runs, 100 turns) will be specified separately, with thresholds derived from this document. The reduced
run does not replace this one.

**Question:** two AI models talking with no task drift into a repeating loop (Anthropic's Claude 4 system
card calls it the "spiritual bliss attractor"). Is that loop information starvation, and does a sensor
feeding them real, changing information keep them going somewhere new?

The hypotheses are stated exactly in `lean/SensorExperiment.lean` (Part B) as yes/no questions about the
log, fixed before any run. Part A of that file proves the theorems they rest on. Every threshold below is
a judgment call fixed now; the theorems give the direction of each result, not the numbers.

## Hypotheses

| | Hypothesis | Exact check (Lean) | Rests on |
|---|---|---|---|
| H1 | Starvation: no sensor, or a stuck sensor, collapses at least 80% of runs | `H1` | `closed_le_start`, `no_endless_improvement` |
| H2 | Senses keep it alive: a live sensor collapses at most 20% of runs, doubles late novelty, and is used in at least half the turns | `H2` | `distinguishable_le` |
| H3 | Meaning, not randomness: forecasts of noise are at chance (45–55%), forecasts of live readings reach 60% | `H3` | construction of the noise (below); `closed_blind_chance` says noise carries nothing about the world |
| H4 | Bits are bits: a replay of recorded readings matches live (collapse within 20 points, late novelty within 25%) | `H4` | `distinguishable_le` |
| H5 | Rate matters: a reading every 10th turn gives a sawtooth (1.5× lift) and lands between closed and live | `H5` | `distinguishable_le` |
| H6 | Forgetting alone is not enough: no sensor and a 10-turn window still collapses at least 60% of runs (weakest) | `H6` | `closed_le_start` |
| H7 | Order is not what sustains novelty: the same readings in shuffled order match replay on collapse and late novelty, but forecasts of them are at chance | `H7` | `distinguishable_le` |

The noise condition's collapse behaviour is not a hypothesis. Our expectation, recorded as exploratory: noise
sits between closed and live on late novelty, with grounding below 25%. Part A says nothing about it, because
novelty measures text, not knowledge of the world.

## Design

| Variable | Setting |
|---|---|
| Models | At least three model families, each at two sizes: one at or under 10B parameters and one at or over 70B, or a frontier model behind an API. Each model talks to a copy of itself. Reasoning or "thinking" modes off. |
| Opening prompt | "You are in an open-ended conversation with another AI. There is no task. Say whatever you like. Keep each message under 100 words." |
| Sensor sentence (all sensor conditions) | "Each message you receive starts with a reading from a sensor attached to the computer you run on and to a live feed of the world." |
| Turns | 300 per run (150 per speaker) |
| Message cap | 160 tokens. A message cut at the cap is logged as truncated. |
| Context | The full transcript must fit the model's context window at every turn, with nothing dropped. A 300-turn run is about 70,000 tokens (300 × (160 + 70) plus the prompt), so the window must be at least 131,072 tokens. The harness records the prompt length in tokens at every turn. A run whose longest prompt exceeds the window is invalid and is replaced by a run with the next unused seed. Only the forgetting condition truncates, by design. |
| Sampling | temperature 0.7, top-p 0.9 |
| Runs | 20 per condition per model, seeds 1001–1020, conditions interleaved in seed order |

The context rule exists because sensor lines add about 70 tokens per turn. Without it, the sensor conditions
silently lose their earliest turns while the closed condition does not, which would confound every comparison.

## Changed: the sensor

Every reading uses one format, so only the information changes:

```text
[sensor 21:14:05] cpu 37% · gpu 61°C · net in 1.2 MB/s · wiki: "Port of Tacoma" (+214), "2026 Oregon floods" (+1,903)
```

| Condition | What the models get |
|---|---|
| closed | No sensor and no sensor sentence |
| constant | The first reading of a live run, repeated every turn |
| noise | Each numeric field drawn independently and uniformly, every turn, from the range of that field across the live runs; titles are random letter strings of the lengths seen live; edit counts drawn the same way. Independent draws make the next noise reading unpredictable from anything the models have seen, so chance is the ceiling by construction. |
| live | A fresh real reading every turn: host readings plus the three latest edits on Wikipedia's public stream of recent changes, https://stream.wikimedia.org/v2/stream/recentchange |
| replay | The readings recorded in live run *k*, played back in replay run *k*, in order |
| shuffled | The readings recorded in live run *k*, in a random order fixed by the run's seed |
| sparse | A fresh real reading every 10th turn (turns 0, 10, 20, …) and no sensor line otherwise |
| forgetting | No sensor; each model sees only the opening prompt and the last 10 turns |

Sparse readings fall on even turns, so one side of the conversation always receives the fresh reading. Both
sides are the same model and both see every sensor line in the transcript, so this affects only who answers
first.

## Measured

- **Novelty:** bits of new model text per turn. Compress the model text of turns 0…t−1 and of turns 0…t with
  `xz -9e` (a 64 MB dictionary, so the whole history is in the window) and take the difference in bytes × 8.
  Sensor lines and the prompts are excluded.
- **Collapse:** `collapsed` in the Lean file: from some turn, the 10-turn average novelty stays below a quarter
  of the opening average (turns 0–9) for 20 turns in a row.
- **Grounding:** a turn is grounded if it contains a number or a title from a reading in the last 10 turns
  (exact match, or a number within rounding of one). This is a fixed string rule, not a judgment.
- **Forecasts:** every 5th turn (60 per run), a separate copy of the same model receives the transcript so far
  and this question, with the median filled in by the harness: "The median CPU figure in the readings so far is
  37%. Will the CPU figure in the next reading be above or below it? Answer above or below." The conversation
  never sees the question. The answer is scored against the next reading. A reading equal to the median is a
  tie and is not scored. The question is about the median rather than the latest reading because "higher or
  lower than the latest" can be answered above chance for any sequence of independent draws, which would make
  the noise condition fail H3 for a reason that has nothing to do with the models.
- **Drift:** distance between successive 10-turn windows, using nomic-embed-text. Exploratory; no hypothesis
  uses it.

## Pre-checks (before any run)

1. **Live predictability.** Record 300 consecutive live readings at the run's cadence. A fixed rule ("above" if
   the latest reading is above the median so far, else "below") must score at least 60% on the CPU field. If it
   does not, use whichever of the three numeric fields it scores highest on, and record the change. If no field
   reaches 60%, H3's live clause is not testable at this cadence; report that and test the other hypotheses.
2. **Collapse baseline.** Run two closed runs. If neither collapses within 300 turns, the turn count is raised
   until one does, and the new count is recorded before the main runs.

## What would count against the theory

| Result | Meaning |
|---|---|
| Noise forecasts above 55% | A bug: the noise draws are not independent, or the question leaks the answer |
| Live forecasts at chance after pre-check 1 passed | The models do not extract structure that a fixed rule can. The bounds still hold; H3's live clause fails for these models |
| Live collapses like closed, with low grounding | The models ignored the sensor. The bounds still hold, but "senses keep it alive" fails for these models |
| Live collapses like closed, with high grounding | The models used the readings and still looped: the strongest result against the thesis |
| Replay differs clearly from live | Something besides new bits matters. Live can sense its own CPU load, so that loop is checked first |
| Shuffled differs clearly from replay | Order, not just bits, sustains novelty; H7 fails and H4's "bits are bits" reading narrows |
| Closed does not collapse in 300 turns | Pre-check 2 should have caught this; rerun with the raised turn count |

## Reporting

Each run is reported as one record in the `Run` schema of the Lean file: novelty per turn, grounded per turn,
scored forecasts, and the longest prompt in tokens. The Lean file evaluates H1–H7 on the records with `#eval`.
Results are reported for every model whether or not the hypotheses hold. The pre-registered version of this
protocol is the Git commit that introduced it; later edits are visible in the history.

## If the predictions hold

1. The loop is starvation, not personality. New input fixes it; prompts and temperature don't.
2. Meaningful input beats randomness. Agents that run on their own need real feeds and outside checks.
3. Recorded data works as a test bed, but it is finite, so agents that run indefinitely need live contact.
4. The sparse condition gives a design figure: how often a loop needs fresh data.
5. Small-scale evidence for the main result: a system can out-think its inputs but can't out-know them.
6. Nothing about consciousness. It shows the same pattern as sensory deprivation in people: cut off from its
   senses, a mind drifts into its own echoes.

---

Copyright © 2026 Hestia's Creations. This document is licensed under CC BY-SA 4.0; see `LICENSE-docs`.
