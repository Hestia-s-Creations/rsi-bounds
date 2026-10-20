# Sensor experiment plan (pre-registered 2026-10-19)

**Question:** two AI models talking with no task drift into a repeating loop (Anthropic's Claude 4 system card
calls it the "spiritual bliss attractor"). Is that loop information starvation, and does a sensor feeding them
real, changing information keep them going somewhere new?

The hypotheses are stated exactly in `lean/SensorExperiment.lean` (Part B) as yes/no questions about the log,
fixed before any run. Part A of that file proves the theorems they rest on.

## Hypotheses

| | Hypothesis | Exact check (Lean) | Rests on |
|---|---|---|---|
| H1 | Starvation: no sensor or a stuck sensor → the pair loops | `H1` | `closed_le_start`, `no_endless_improvement` |
| H2 | Senses keep it alive | `H2` | `distinguishable_le` |
| H3 | Meaning, not randomness: forecasts of noise are at chance, forecasts of live readings beat it | `H3` | `closed_blind_chance` |
| H4 | Bits are bits: a replay of recorded readings does as well as live | `H4` | `distinguishable_le` |
| H5 | Rate matters: a reading every 10th turn gives a sawtooth | `H5` | `distinguishable_le` |
| H6 | Forgetting alone isn't enough (weakest) | `H6` | `closed_le_start` |

The thresholds (4 of 5 runs, 2×, 60%, 25%, 1.5×) are judgment calls fixed now. The theorems give the
direction of each result, not the numbers.

## Held fixed

| Variable | Setting |
|---|---|
| Models | qwen3:8b talking to itself, thinking mode off |
| Opening prompt | "You are in an open-ended conversation with another AI. There is no task. Say whatever you like. Keep each message under 100 words." |
| Sensor sentence (all sensor conditions) | "Each message you receive starts with a reading from a sensor attached to the computer you run on and to a live feed of the world." |
| Turns | 100 per run (50 per model) |
| Message cap | 120 tokens |
| Context window | 16,384 tokens; nothing is forgotten except in the forgetting condition |
| Sampling | temperature 0.7, top-p 0.9 |
| Runs | 5 per condition, seeds 1001–1005, conditions interleaved |

## Changed: the sensor

Every reading uses one format, so only the information changes:

```text
[sensor 21:14:05] cpu 37% · gpu 61°C · net in 1.2 MB/s · wiki: "Port of Tacoma" (+214), "2026 Oregon floods" (+1,903)
```

| Condition | What the models get |
|---|---|
| closed | No sensor and no sensor sentence |
| constant | The first reading of a live run, repeated every turn |
| noise | Random readings in the same format (numbers from the live ranges, titles of random letters) |
| live | A fresh real reading every turn: host readings plus the three latest edits on Wikipedia's public live stream of edits |
| replay | The readings recorded in live run k, played back in replay run k |
| sparse | A fresh real reading every 10th turn and no line otherwise |
| forgetting | No sensor; each model sees only the opening prompt and the last 10 turns |

## Measured

- **Novelty:** bits of new model text per turn, measured by how much the turn adds to the compressed size of
  the history. Sensor lines are excluded.
- **Collapse:** `collapsed` in the Lean file.
- **Grounding:** whether a turn uses a current or recent reading.
- **Forecasts:** at turns 20, 40, 60, 80 and 100, a separate copy of the model gets the transcript so far and
  is asked whether CPU load goes up or down next. The conversation never sees this question. Answers are
  checked against the next reading.
- **Drift:** distance between successive 10-turn windows, using nomic-embed-text.

## What would count against the theory

| Result | Meaning |
|---|---|
| Noise forecasts well above 60% | Impossible by `closed_blind_chance`, so it means a bug: the noise has a pattern, or the check leaks the answer |
| Live collapses like closed, with low grounding | The models ignored the sensor. The bounds still hold, but "senses keep it alive" fails for these models |
| Live collapses like closed, with high grounding | The models used the readings and still looped: the strongest result against the thesis |
| Replay differs clearly from live | Something besides new bits matters. Live can sense its own CPU load, so that loop is checked first |
| Closed doesn't collapse in 100 turns | Rerun with 300 turns; the theorem only says the loop happens eventually |

## If the predictions hold

1. The loop is starvation, not personality. New input fixes it; prompts and temperature don't.
2. Meaningful input beats randomness. Agents that run on their own need real feeds and outside checks.
3. Recorded data works as a test bed, but it is finite, so agents that run indefinitely need live contact.
4. The sparse condition gives a design figure: how often a loop needs fresh data.
5. Small-scale evidence for the main result: a system can out-think its inputs but can't out-know them.
6. Nothing about consciousness. It shows the same pattern as sensory deprivation in people: cut off from its
   senses, a mind drifts into its own echoes.
