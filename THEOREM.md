# Bounds on recursive self-improvement

Started 2026-10-19 from "the notebook": three pages of handwritten notes by Nicole Welch and Tim of
Hestia's Creations, written before any of this, that set out to prove that true AI recursive
self-improvement requires both a rate of forgetting and outside input. The notebook is not in this
repository. Where the text below mentions the notebook's notation (M_T, F_T) or the notebook's goal, it
means those pages. Checks: `python3 checks/check_bounds.py` (all pass, 2026-10-19).

## Verdict

**There can't be one theorem that predicts the growth rate of intelligence for every self-improving
system. Theorem 7 proves this.** Predicting where an arbitrary self-modifying system ends up is
undecidable when its memory is unbounded. With bounded memory it is decidable, but in general
nothing does much better than running the system.

What can be proved, and is proved below:

1. **Knowledge is paid for in bits.** What a system knows about the world grows by at most the number of bits that
   come in from outside, and never exceeds its memory. A closed system can't learn anything new about the world. (Thms 1–2)
2. **That gives a hard speed limit for world-dependent skills.** The time to reach a given error rate is at least
   (missing bits) ÷ (input bits per step), however smart the system is. (Thm 2, corollary)
3. **A closed system's improvement must stop.** The ceiling can be astronomically high. (Thm 3)
4. **Forgetting is forced.** Over any period, a finite memory forgets at least as many bits as it learns, minus its
   capacity. In the long run the forgetting rate equals the learning rate. (Thm 4)
5. **Two minds:** together they know no more than their combined inputs allow. One can know more than its own inputs
   allow by learning from the other. (Thm 5)
6. **Compute-only skills** (math, code, games, the system's own algorithms) are not information-limited. They follow a
   growth law whose shape depends on one measured number, *r* (the returns to research). The law is an exact
   statement about a model, not a theorem about the world. Current estimates of *r* fall on both sides of 1, the
   line between slowing down and exploding. (Thm 6)

So the honest answer has two parts. For knowledge, there's a proven, usable upper bound on the rate. For skill
there's a conditional rate law, and the evidence doesn't yet settle which regime we're in.

## Setup (fixes the notebook's notation)

- **World** W: a random variable on a finite set 𝒲. It represents the facts a task depends on, and the system's
  actions don't change it. (If the system can change W, it can make the world match its memory. That case is
  outside these theorems.)
- **State** S_t: everything the system is at step t, written in at most **B bits**. That includes memory, policy,
  and *its own update rule*, so self-modification is allowed. The notebook's M_T is one part of S_T. It isn't a
  subset, because S_T is a tuple.
- **Input** X_t: whatever enters from outside at step t. It can depend on W and on the system's state, so the system
  can choose what to look at. **Budget:** I(W; X_t | S_t) ≤ b_t. It's enough that X_t takes at most 2^{b_t} values.
- **Internal randomness** R_t: fresh coin flips, independent of (W, S_t, X_t).
- **Update:** S_{t+1} = Φ(S_t, X_t, R_t), where Φ is the fixed hardware or interpreter that reads and runs whatever
  update rule is stored in S_t. This fixes the notebook's F_T: S_T × M_T → S_{T+1}, which mixed up particular
  states and sets of states.
- **Score** U: S → ℝ, **fixed and outside the system**. If the system can edit U, it can "improve" by redefining
  the score.
- **Closed after T₀:** X_t carries no information (b_t = 0) for every t ≥ T₀.
- I(·;·) is mutual information in bits: how much knowing one thing reduces uncertainty about another. H is entropy.

## Theorems and proofs

### Lemma 1 (one-step ledger)
I(W; S_{t+1}) ≤ I(W; S_t) + I(W; X_t | S_t).

*Proof.* S_{t+1} is a function of (S_t, X_t, R_t), so by the data processing inequality
I(W; S_{t+1}) ≤ I(W; S_t, X_t, R_t). By the chain rule this equals I(W; S_t, X_t) + I(W; R_t | S_t, X_t). The second
term is 0 because R_t is independent of (W, S_t, X_t). Applying the chain rule again,
I(W; S_t, X_t) = I(W; S_t) + I(W; X_t | S_t). ∎

### Theorem 1 (information ledger)
I(W; S_t) ≤ min( B, I(W; S_0) + Σ_{s<t} b_s ).
If the system is closed after T₀, then I(W; S_t) is non-increasing for t ≥ T₀.

*Proof.* Sum Lemma 1 over the steps and use the budget. Also I(W; S_t) ≤ H(S_t) ≤ B. When closed, the input term is 0. ∎

### Theorem 2 (performance ceiling, from Fano's inequality)
For any task that needs a guess Ŵ of W made from S_t (with any amount of computation and randomness):

  P(Ŵ ≠ W) ≥ ( H(W) − I(W; S_t) − 1 ) / log₂|𝒲|  ≥  ( H(W) − min(B, I₀ + Σ b) − 1 ) / log₂|𝒲|.

*Proof.* Fano: H(W | Ŵ) ≤ 1 + P_e·log₂|𝒲|. Data processing: H(W | Ŵ) ≥ H(W | S_t) = H(W) − I(W; S_t).
Rearrange, then apply Theorem 1. ∎

**Corollary (speed limit).** To reach error ≤ ε, the system needs B ≥ H(W) − 1 − ε·log₂|𝒲|, and with a constant
input rate of b bits per step:

  t ≥ ( H(W) − 1 − ε·log₂|𝒲| − I₀ ) / b.

Worked number: take a million independent yes/no facts about something unexplored (H = log₂|𝒲| = 10⁶ bits) and a
target error of 1%. "Error" here is P(Ŵ ≠ W), the chance that the guess of the whole million-bit vector is wrong
anywhere. The system needs 989,999 bits. At 1,000 bits per day of experimental results, starting from zero, that
takes **at least 990 days**. If "1% error" instead means 1% of the facts wrong, the rate-distortion converse for
uniform bits gives I(W; S_t) ≥ 10⁶·(1 − h(0.01)) ≈ 919,000 bits, so at least 919 days: the same picture. No level
of intelligence shortens this. Only more or better experiments (a larger b) do. An "explosion" in world knowledge
therefore needs an explosion in the input rate.

### Theorem 3 (closed systems stop improving)
If Φ is deterministic and the system is closed after T₀, the run S_{T₀}, S_{T₀+1}, … becomes periodic within 2^B
steps. A run of strictly increasing U lasts at most 2^B − 1 steps, and strict improvement can't continue forever.
(With randomness, the net improvement U(S_t) − U(S_{T₀}) is still at most max U − U(S_{T₀}), which needs no theorem.
The sum of all rises is not bounded, because U can rise and fall forever.)

*Proof.* There are at most 2^B states, and each state determines the next, so a state repeats within 2^B steps
(pigeonhole) and the run cycles from then on. A strictly increasing U can't revisit a state, so it can't go around
a cycle. ∎

*Limit on usefulness:* 2^B for a real model is astronomically large. This theorem rules out unlimited closed
improvement and nothing more practical. Theorems 1–2 are the ones that bite.

### Theorem 4 (forgetting law)
Let W = (W₁, …, W_n) be **independent** facts, and let K_t = Σᵢ I(Wᵢ; S_t) be the total knowledge held about
individual facts. Then:

(a) K_t ≤ I(W; S_t) ≤ B.
(b) Over any period 0..T, write *learned* for the sum of all per-fact increases and *forgotten* for the sum of all
per-fact decreases. Then forgotten = learned − (K_T − K_0) ≥ learned − B.

So the long-run forgetting rate ≥ the long-run learning rate − B/T, which approaches the learning rate as T grows.
A system that keeps learning keeps forgetting at the same rate, and Theorem 1 caps that rate at the input rate.
To keep δ bits about each fact, it can hold at most B/δ facts at once.

*Proof.* (a) Chain rule: I(W; S) = Σᵢ I(Wᵢ; S | W_{<i}). Because the facts are independent,
I(Wᵢ; S | W_{<i}) = H(Wᵢ) − H(Wᵢ | S, W_{<i}) ≥ H(Wᵢ) − H(Wᵢ | S) = I(Wᵢ; S). (b) This is bookkeeping:
K_T − K_0 = learned − forgotten, and K ≤ B. ∎

*Scope:* the theorem needs independent facts. When facts share structure, a general rule can hold many of them at
once (compression), and the bound applies to the joint quantity I(W; S) instead. What to forget matters too.
Gerstgrasser et al. (2024) find that dropping the original real data causes collapse while keeping it avoids
collapse. Forget detail and outdated material; keep the grounding.

### Theorem 5 (two minds)
For two systems A and B that exchange messages freely, with budgets in the alphabet-size form (X^A_t takes at most
2^{b^A_t} values and X^B_t at most 2^{b^B_t} values):
I(W; S^A_t, S^B_t) ≤ I(W; S^A_0, S^B_0) + Σ (b^A_s + b^B_s).
Messages between them add nothing to what the pair knows jointly. Either one alone can exceed its own budget by
learning from the other. (In the check, B has b^B = 0 and still learns 2 bits.)

*Proof.* Apply Theorem 1 to the joint state (S^A, S^B). Its input is the pair (X^A, X^B), which takes at most
2^{b^A + b^B} values, so the joint budget is b^A + b^B. Messages are internal. ∎

The alphabet-size form matters here. The two mutual-information budgets I(W; X^A | S^A) ≤ b^A and
I(W; X^B | S^B) ≤ b^B on their own do not bound the joint term I(W; X^A, X^B | S^A, S^B). Example: Z is a fair bit
independent of W, mind B holds Z, and mind A receives W ⊕ Z. Each budget is 0, yet the pair learns W. The check
script uses alphabet-size budgets.

This sharpens the notebook's paragraph. "More than the sum of its parts" holds for *skill*: the joint system can
reach computations neither could reach alone. It does not hold for *knowledge* of the world, which is capped by
their combined inputs.

### Theorem 6 (growth law for compute-only skill; conditional)
Model, following Jones (1995) as used by Epoch and Forethought: software efficiency A (how much more capability
the same hardware delivers) grows as (1/A)·dA/dt = θ·A^{−β}·E^λ. Here E is research effort, λ ≤ 1 is the penalty
for doing research in parallel, and r = λ/β is the returns to research: how many doublings of A each doubling of
cumulative effort buys. When the AI does the research on fixed hardware, E = c·A, so

  dA/dt = k·A^{1+p},  with  **p = λ(1 − 1/r)**  and  k = θ·c^λ.

Exact solutions:
- r = 1 (p = 0): A(t) = A₀·e^{kt}. Every doubling takes the same time.
- r < 1 (p < 0): A(t) = (A₀^{−p} − p·k·t)^{−1/p}. Polynomial growth, with each doubling slower than the last.
- r > 1 (p > 0): the same formula, which **reaches infinity at t\* = T₁ / (1 − 2^{−p})**, where T₁ is the first
  doubling time. Each doubling takes 2^{−p} times as long as the previous one.

In practice a physical or algorithmic ceiling A_max stops it first. With D = log₂(A_max/A₀) doublings, the time to
reach the ceiling is T₁·(1 − 2^{−pD}) / (1 − 2^{−p}).

*Proof.* Separate variables: ∫A^{−1−p} dA = k·dt. Doubling-time ratio: going from A to 2A takes
A^{−p}(1 − 2^{−p})/(p·k), which scales as A^{−p}. ∎ (Also checked numerically against an ODE solver.)

**Worked numbers** (time to grow A a million-fold, i.e. 20 doublings, in units of the first doubling time T₁):

| r | λ | p | each doubling vs last | time to ∞ | 20 doublings |
|---|---|---|---|---|---|
| 0.5 | 1 | −1.00 | 2× longer | never | ~1,000,000 T₁ |
| 0.83 (chess, Epoch) | 1 | −0.20 | 15% longer | never | 106 T₁ |
| 1.0 | 1 | 0 | same | never | 20 T₁ |
| 1.4 (image recognition, Epoch median) | 1 | +0.29 | 18% shorter | 5.6 T₁ | 5.5 T₁ |
| 1.4 | 0.5 | +0.14 | 9% shorter | 10.6 T₁ | 9.1 T₁ |
| 2 | 1 | +0.50 | 29% shorter | 3.4 T₁ | 3.4 T₁ |

Forethought's best guess at constant hardware is r ≈ 0.5–2. That spans the first and last rows, about six orders
of magnitude in time to a million-fold gain. **Evidence about r, not mathematics, is what blocks a prediction.**

What Theorem 6 does *not* say:
- A is efficiency, not intelligence. How efficiency turns into capability is a separate empirical curve (scaling laws).
- It assumes r stays constant. Real returns fall near the ceiling, which only slows things down.
- It covers compute-only skill. Any world-dependent part of a task is still capped by Theorems 1–2.

### Theorem 7 (exact general prediction is impossible)
(a) **Unbounded memory:** no algorithm can take an arbitrary self-improving system (S₀, Φ) and a threshold u and
decide whether U(S_t) ≥ u at some step t.
*Proof:* given any program P, build a system that runs P one step per update and sets U = 1 if P halts, else 0.
Deciding whether U ever reaches 1 would decide the halting problem. ∎

(b) **B-bit memory:** the question is decidable (simulate up to 2^B steps), but when Φ is given as a program it is
PSPACE-complete. This is the standard result for linear-bounded automata and for reachability in graphs described
by a program (see Sipser, *Introduction to the Theory of Computation*). Unless P = PSPACE, which is widely believed
false, no general method predicts the outcome in polynomial time.

So a rate theorem has to come from **bounds** (Thms 1–5) or from a **model with measured parameters** (Thm 6). It
can't come from analyzing the system itself in general.

## How this answers the notebook's goal

| Notebook claim | Status |
|---|---|
| Circular self-improvement requires outside input | **Proved for knowledge** (Thms 1–2). **Proved for unlimited improvement** (Thm 3), with an astronomically high ceiling. **False for compute-only skill** up to that ceiling: AlphaZero is the counterexample. |
| …and requires a rate of forgetting | **Proved for sustained learning:** forgetting rate → learning rate (Thm 4). **False for single steps:** a system can improve without forgetting anything. |
| Two minds: the limit is the reachable set of the combined graph | **Proved for skill. False for knowledge:** joint knowledge ≤ combined inputs (Thm 5). |

## Checks

`checks/check_bounds.py` computes exact joint distributions for hundreds of random small systems. They include
stochastic updates, inputs that depend on the system's state, self-chosen observations, closed phases, shift
registers, and two coupled minds. The script tests every inequality above. All pass. Lemma 1, Theorem 1,
Theorem 3 and Theorem 4(b) are reached **exactly** (gap 0) on some systems, so they can't be tightened. The growth
law matches an ODE solver to a relative error of 7×10⁻¹⁰. Theorem 7 is a proof plus a standard result; nothing is
computed for it.

## Sources

- Epoch AI, "Do the returns to software R&D point towards a singularity?" (2024): Stockfish r ≈ 0.83 ± 0.15; the
  median for other domains is above 1, but not significantly. https://epoch.ai/blog/do-the-returns-to-software-rnd-point-towards-a-singularity
- Davidson & Houlden (Forethought), "Will AI R&D automation cause a software intelligence explosion?": r best guess
  ~0.5–2 at constant hardware; image recognition median 1.4 (0.8–2.4).
  https://www.forethought.org/research/will-ai-r-and-d-automation-cause-a-software-intelligence-explosion
- Forethought, "How quick and big would a software intelligence explosion be?" (2025).
  https://www.forethought.org/research/how-quick-and-big-would-a-software-intelligence-explosion-be
- Zenil, Uthamacumaran & Ozelim, "Large Language Models are Shannon Lossy Compressors Not Solomonoff Induction
  Estimators: Self-improvement and Singularity Are Not Near Without Symbolic Model Synthesis" (2026; version 1 was
  titled "On the Limits of Self-Improving in LLMs…"): collapse when outside signal vanishes. https://arxiv.org/abs/2601.05280
- Huang et al., "Self-Improvement in Language Models: The Sharpening Mechanism" (ICLR 2025). https://arxiv.org/abs/2412.01951
- Gerstgrasser et al., "Is Model Collapse Inevitable?" (2024). https://arxiv.org/abs/2404.01413
- Richards & Frankland, "The Persistence and Transience of Memory," Neuron 2017.
- Standard results, not re-checked this session: Fano's inequality, data processing, and the rate-distortion
  function R(D) = 1 − h(D) of a fair bit under Hamming distortion (Cover & Thomas, *Elements of Information Theory*);
  the halting problem; PSPACE-completeness of LBA acceptance (Sipser).

---

Copyright © 2026 Hestia's Creations. This document is licensed under CC BY-SA 4.0; see `LICENSE-docs`.
