# The notebook

Three handwritten pages by Nicole Welch and Timothy Miller Allen, written before any of the work in this
repository. They are the starting point that `THEOREM.md` keeps score against. This is a transcription of
the pages as written, including a crossed-out assumption, with the notation unchanged.

Markers: `[crossed out]` for text struck through on the page, `[unclear]` where the handwriting could not be
read with confidence, `[margin]` for notes written in the margin.

## Page 1

**Goal:** prove AI circular self-improvement requires a rate of forgetting **and** outside input.

Assumptions

- Finite AI memory = F_N [unclear symbols follow]
- [crossed out] Finite attention: finite amount of info an AI can reason over at a given time, A(t)
  (context ext. from outside). [margin] "meh"
- Def. circular self-improvement: ∀ AI systems S s.t. improvement, ∃ info I ∈ S [crossed-out words]
  such that f(I) = n where n ∈ S [unclear whether ∈ or ∉].

[margin, rotated, unclear] "?in: predictor (turn on: killing :)"

Let S_T be the complete state of the AI system at time T.

S_T := (M_T, P_T, F_T)

The system at time T is made of its memory, its policy and reasoning process, and its update function.

M_T ⊆ S_T

Memory is a part of the system.

|M_T| < ∞

The system's memory is finite.

I ∈ M_T

The information item I already exists inside the system's memory.

## Page 2

F_T : S_T × M_T → S_{T+1}

The update function takes the current system and some memory content, then produces the next system state.

S_{T+1} = F_T(S_T, I)

The next version of the system is created by applying the update function to the current system and an
internal information item.

U : S → ℝ

The eval function assigns a real-number score to any possible system state.

U(S_{T+1}) > U(S_T)

The next system state is better than the current system state according to the eval.

SelfImprove(S_T) ⟺ ∃ I ∈ M_T : (U(F_T(S_T, I)) > U(S_T))

The system self-improves at time T if there exists some information already inside its memory such that
using that information to update itself produces a better system state.

## Page 3

Closed(S, T₀) ⟺

The system is closed after time T₀ if, after that time, no new outside information enters the system.

C_T : M_T → M_{T+1}

The memory update function transforms the current memory into the next memory.

Two minds do not just add memory. They create a relation. If that relation lets each mind unlock
transformations the other could not reach alone, the joint system can become more powerful than the sum of
its parts. The limit is the highest value state reachable in the combined interaction graph, not the raw
size of either mind.

## What became of it

| Notebook item | Where it went |
|---|---|
| Goal: forgetting and outside input | `THEOREM.md`, "How this answers the notebook's goal" |
| S_T = (M_T, P_T, F_T), finite memory | The state S_t of at most B bits in the Setup; the update rule is part of the state, so self-modification is allowed |
| F_T : S_T × M_T → S_{T+1} | Replaced by S_{t+1} = Φ(S_t, X_t, R_t), where Φ is the fixed interpreter and the stored rule is inside S_t |
| U : S → ℝ | Kept, with the condition that the system cannot edit U |
| SelfImprove and Closed | Theorem 3 (closed systems stop improving) |
| C_T : M_T → M_{T+1} | Theorem 4 (forgetting law) |
| Two minds | Theorem 5: true for skill, false for knowledge |

---

Copyright © 2026 Hestia's Creations. This document is licensed under CC BY-SA 4.0; see `LICENSE-docs`.
