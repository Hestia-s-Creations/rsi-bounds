-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (C) 2026 Hestia's Creations
import Mathlib

/-!
# Sensor experiment: the thesis in Lean

Part A is the model and the theorems the hypotheses rest on. Every statement there is proved,
and Lean checks the proofs.

Part B is the hypotheses. They are claims about the world, so Lean can't prove them. Each one is
written as an exact yes/no question about the experiment's log, fixed before any run, so the data
answers it and nobody can reinterpret it afterwards.

Part A is the *counting* version of the theorems in "Bounds on recursive self-improvement": the
system is deterministic and knowledge is measured as the number of worlds it can tell apart
(log₂ of that number is bits). The Shannon versions in that doc need information theory that
Mathlib doesn't have yet. They say the same thing with probabilities.
-/

namespace SensorExperiment

open Finset

/-! ## Part A. The model -/

/-- A deterministic system that lives in some world `w : W`.
* `init w` is its starting state (it may already know something about its world).
* `sense w t s` is the sensor reading at turn `t` when it is in state `s`
  (so it may choose where to look).
* `step s x` is its next state after reading `x` in state `s`. -/
structure System (W S X : Type*) where
  init : W → S
  sense : W → ℕ → S → X
  step : S → X → S

variable {W S X : Type*}

/-- The system's state after `t` turns, in world `w`. -/
def System.run (M : System W S X) (w : W) : ℕ → S
  | 0 => M.init w
  | t + 1 => M.step (M.run w t) (M.sense w t (M.run w t))

/-- How many different states the system can be in at turn `t`, across all possible worlds.
This is how many worlds it can tell apart; `log₂` of it is its knowledge in bits. -/
def System.distinguishable [Fintype W] [DecidableEq S] (M : System W S X) (t : ℕ) : ℕ :=
  (univ.image fun w => M.run w t).card

/-- The sensor is *closed*: what it reports never depends on which world the system is in.
No sensor, a sensor stuck on one reading, and a sensor reporting noise (a fixed random sequence
that has nothing to do with the world) are all closed. -/
def System.Closed (M : System W S X) : Prop :=
  ∀ w w' t s, M.sense w t s = M.sense w' t s

/-! ### Theorem 1 (ledger): each turn multiplies what can be told apart by at most the number of
possible readings, and memory caps it. -/

theorem distinguishable_succ_le [Fintype W] [DecidableEq S] [Fintype X]
    (M : System W S X) (t : ℕ) :
    M.distinguishable (t + 1) ≤ M.distinguishable t * Fintype.card X := by
  classical
  unfold System.distinguishable
  have h : (univ.image fun w => M.run w (t + 1)) ⊆
      ((univ.image fun w => M.run w t) ×ˢ (univ : Finset X)).image
        (fun p => M.step p.1 p.2) := by
    intro s hs
    obtain ⟨w, -, rfl⟩ := mem_image.mp hs
    exact mem_image.mpr ⟨(M.run w t, M.sense w t (M.run w t)),
      mem_product.mpr ⟨mem_image.mpr ⟨w, mem_univ _, rfl⟩, mem_univ _⟩, rfl⟩
  calc _ ≤ _ := card_le_card h
    _ ≤ _ := card_image_le
    _ = _ := by rw [card_product, card_univ]

theorem distinguishable_le [Fintype W] [DecidableEq S] [Fintype X]
    (M : System W S X) (t : ℕ) :
    M.distinguishable t ≤ M.distinguishable 0 * Fintype.card X ^ t := by
  induction t with
  | zero => simp
  | succ n ih =>
    calc M.distinguishable (n + 1) ≤ M.distinguishable n * Fintype.card X :=
          distinguishable_succ_le M n
      _ ≤ M.distinguishable 0 * Fintype.card X ^ n * Fintype.card X :=
          Nat.mul_le_mul_right _ ih
      _ = M.distinguishable 0 * Fintype.card X ^ (n + 1) := by ring

theorem distinguishable_le_memory [Fintype W] [Fintype S] [DecidableEq S]
    (M : System W S X) (t : ℕ) :
    M.distinguishable t ≤ Fintype.card S :=
  card_le_univ _

/-- With a closed sensor, what the system can tell apart never grows. -/
theorem closed_succ_le [Fintype W] [Nonempty W] [DecidableEq S]
    (M : System W S X) (hM : M.Closed) (t : ℕ) :
    M.distinguishable (t + 1) ≤ M.distinguishable t := by
  classical
  obtain ⟨w₀⟩ := ‹Nonempty W›
  unfold System.distinguishable
  have h : (univ.image fun w => M.run w (t + 1)) =
      (univ.image fun w => M.run w t).image (fun s => M.step s (M.sense w₀ t s)) := by
    rw [image_image]
    congr 1
    funext w
    simp only [Function.comp, System.run, hM w w₀]
  rw [h]
  exact card_image_le

theorem closed_le_start [Fintype W] [Nonempty W] [DecidableEq S]
    (M : System W S X) (hM : M.Closed) (t : ℕ) :
    M.distinguishable t ≤ M.distinguishable 0 := by
  induction t with
  | zero => exact le_refl _
  | succ n ih => exact (closed_succ_le M hM n).trans ih

/-! ### Theorem 2 (ceiling): any way of guessing the world from the state is right in at most
as many worlds as the system can tell apart. -/

theorem correct_guesses_le [Fintype W] [DecidableEq W] [DecidableEq S]
    (M : System W S X) (t : ℕ) (g : S → W) :
    (univ.filter fun w => g (M.run w t) = w).card ≤ M.distinguishable t := by
  unfold System.distinguishable
  apply card_le_card_of_injOn (fun w => M.run w t)
  · intro w _
    exact mem_image.mpr ⟨w, mem_univ _, rfl⟩
  · intro a ha b hb hab
    have ha' : g (M.run a t) = a := (mem_filter.mp ha).2
    have hb' : g (M.run b t) = b := (mem_filter.mp hb).2
    rw [← ha', ← hb']
    exact congrArg g hab

/-- Speed limit: to be right in `k` worlds, the system needs `k ≤ (start) × (readings)^t`,
and `k` can never exceed its number of memory states. -/
theorem speed_limit [Fintype W] [DecidableEq W] [Fintype S] [DecidableEq S] [Fintype X]
    (M : System W S X) (t : ℕ) (g : S → W) (k : ℕ)
    (hk : k ≤ (univ.filter fun w => g (M.run w t) = w).card) :
    k ≤ M.distinguishable 0 * Fintype.card X ^ t ∧ k ≤ Fintype.card S :=
  ⟨hk.trans ((correct_guesses_le M t g).trans (distinguishable_le M t)),
   hk.trans ((correct_guesses_le M t g).trans (distinguishable_le_memory M t))⟩

/-- A system that starts knowing nothing and has a closed sensor is right in at most one world:
chance level, whatever it computes. This is the basis of H3: noise teaches nothing. -/
theorem closed_blind_chance [Fintype W] [Nonempty W] [DecidableEq W] [DecidableEq S]
    (M : System W S X) (hM : M.Closed) (hblind : ∀ w w', M.init w = M.init w')
    (t : ℕ) (g : S → W) :
    (univ.filter fun w => g (M.run w t) = w).card ≤ 1 := by
  have h0 : M.distinguishable 0 ≤ 1 := by
    unfold System.distinguishable
    apply card_le_one.mpr
    intro a ha b hb
    obtain ⟨w, -, rfl⟩ := mem_image.mp ha
    obtain ⟨w', -, rfl⟩ := mem_image.mp hb
    exact hblind w w'
  exact (correct_guesses_le M t g).trans ((closed_le_start M hM t).trans h0)

/-! ### Theorem 3 (no endless improvement): a closed loop on finitely many states can't keep
strictly improving forever, and a strictly improving run is shorter than the number of states. -/

theorem no_endless_improvement [Finite S] (f : S → S) (U : S → ℝ) (s : S) :
    ¬ StrictMono (fun n : ℕ => U (f^[n] s)) := by
  intro h
  obtain ⟨i, j, hij, heq⟩ := Finite.exists_ne_map_eq_of_infinite (fun n : ℕ => f^[n] s)
  exact hij (h.injective (congrArg U heq))

theorem improving_run_le_states [Fintype S] (f : S → S) (U : S → ℝ) (s : S) (n : ℕ)
    (h : StrictMono fun i : Fin (n + 1) => U (f^[i] s)) :
    n + 1 ≤ Fintype.card S := by
  have := Fintype.card_le_of_injective (fun i : Fin (n + 1) => f^[i] s)
    (fun a b hab => h.injective (congrArg U hab))
  simpa using this

/-! ### Theorem 4 (forgetting law): from a record `k t` of what is held at each turn,
forgotten = learned − net growth, so forgotten ≥ learned − memory. -/

/-- Total of every rise in `k` over turns `0 … T`. -/
def learned (k : ℕ → ℝ) (T : ℕ) : ℝ := ∑ t ∈ range T, max (k (t + 1) - k t) 0

/-- Total of every fall in `k` over turns `0 … T`. -/
def forgotten (k : ℕ → ℝ) (T : ℕ) : ℝ := ∑ t ∈ range T, max (k t - k (t + 1)) 0

theorem forgotten_eq (k : ℕ → ℝ) (T : ℕ) :
    forgotten k T = learned k T - (k T - k 0) := by
  unfold forgotten learned
  rw [← sum_range_sub k T, ← sum_sub_distrib]
  refine sum_congr rfl fun t _ => ?_
  rcases le_total (k (t + 1) - k t) 0 with h | h
  · rw [max_eq_right h, max_eq_left (by linarith)]; ring
  · rw [max_eq_left h, max_eq_right (by linarith)]; ring

theorem forgetting_law (k : ℕ → ℝ) (T : ℕ) (B : ℝ) (hstart : 0 ≤ k 0) (hcap : k T ≤ B) :
    learned k T - B ≤ forgotten k T := by
  rw [forgotten_eq]
  linarith

/-- The same law summed over many facts `i ∈ F`, given that the total held stays within memory
(in the Shannon version this cap is Theorem 4(1), which needs the facts to be independent). -/
theorem forgetting_law_facts {ι : Type*} (F : Finset ι) (k : ι → ℕ → ℝ) (T : ℕ) (B : ℝ)
    (hstart : ∀ i ∈ F, 0 ≤ k i 0) (hcap : ∑ i ∈ F, k i T ≤ B) :
    ∑ i ∈ F, learned (k i) T - B ≤ ∑ i ∈ F, forgotten (k i) T := by
  have h : ∑ i ∈ F, forgotten (k i) T =
      ∑ i ∈ F, learned (k i) T - (∑ i ∈ F, k i T - ∑ i ∈ F, k i 0) := by
    simp only [forgotten_eq, sum_sub_distrib]
  have h0 : 0 ≤ ∑ i ∈ F, k i 0 := sum_nonneg hstart
  linarith

/-! ### Theorem 5 (two minds): two minds that talk freely are one system whose sensor is the pair
of their sensors; talking adds nothing to what the pair can tell apart. -/

theorem two_minds {SA SB XA XB : Type*} [Fintype W] [DecidableEq SA] [DecidableEq SB]
    [Fintype XA] [Fintype XB] (M : System W (SA × SB) (XA × XB)) (t : ℕ) :
    M.distinguishable t ≤
      M.distinguishable 0 * (Fintype.card XA * Fintype.card XB) ^ t := by
  simpa [Fintype.card_prod] using distinguishable_le M t

/-! ### Theorem 6 (growth law): with the AI doing its own research, efficiency grows as
`dA/dt = k·A^(1+p)` with `p = λ(1 − 1/r)`. Each doubling takes `2^(−p)` times as long as the one
before, so when `r > 1` the doublings shrink and the total time is finite. -/

/-- With `β = λ / r`, the Jones exponent `1 − β + λ` is `1 + p`. -/
theorem feedback_exponent (lam r : ℝ) (hr : r ≠ 0) :
    1 - lam / r + lam = 1 + lam * (1 - 1 / r) := by
  field_simp
  ring

/-- The feedback strength is positive exactly when returns to research exceed 1. -/
theorem feedback_pos_iff (lam r : ℝ) (hl : 0 < lam) (hr : 0 < r) :
    0 < lam * (1 - 1 / r) ↔ 1 < r := by
  rw [mul_pos_iff_of_pos_left hl, sub_pos, div_lt_one hr]

/-- Time for `A` to double, from the exact solution of `dA/dt = k·A^(1+p)`. -/
noncomputable def doublingTime (p k A : ℝ) : ℝ := (A ^ (-p) - (2 * A) ^ (-p)) / (p * k)

theorem doublingTime_next (p k A : ℝ) (hA : 0 ≤ A) :
    doublingTime p k (2 * A) = (2 : ℝ) ^ (-p) * doublingTime p k A := by
  unfold doublingTime
  have h1 : (2 * A) ^ (-p) = (2 : ℝ) ^ (-p) * A ^ (-p) := Real.mul_rpow (by norm_num) hA
  have h2 : (2 * (2 * A)) ^ (-p) = (2 : ℝ) ^ (-p) * (2 * A) ^ (-p) :=
    Real.mul_rpow (by norm_num) (by positivity)
  rw [h2, h1]
  ring

theorem doublingTime_nth (p k A : ℝ) (hA : 0 ≤ A) (n : ℕ) :
    doublingTime p k (2 ^ n * A) = ((2 : ℝ) ^ (-p)) ^ n * doublingTime p k A := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [pow_succ, mul_comm (2 ^ n) 2, mul_assoc,
      doublingTime_next p k _ (by positivity), ih, pow_succ]
    ring

/-- When `p > 0`, each doubling is shorter than the last. -/
theorem doublings_shrink (p : ℝ) (hp : 0 < p) : (2 : ℝ) ^ (-p) < 1 :=
  Real.rpow_lt_one_of_one_lt_of_neg (by norm_num) (by linarith)

/-- Infinitely many doublings, each `q` times the last, take `T₁ / (1 − q)` in total. -/
theorem total_time (T₁ q : ℝ) (hq0 : 0 ≤ q) (hq1 : q < 1) :
    ∑' n : ℕ, T₁ * q ^ n = T₁ / (1 - q) := by
  rw [tsum_mul_left, tsum_geometric_of_lt_one hq0 hq1, div_eq_mul_inv]

/-! ## Part B. The hypotheses, as yes/no questions about the log

Nothing here is proved. Each hypothesis is a `Prop` about the recorded results `R`, and the data
decides it. The thresholds (4 of 5 runs, 2×, 1/2, …) are judgment calls fixed now, before any run.
They don't follow from Part A. Part A says which way each result should go. -/

/-- The seven sensor conditions. -/
inductive Condition
  | closed      -- no sensor at all
  | constant    -- a sensor stuck on one reading
  | noise       -- random readings in the same format
  | live        -- real, changing readings
  | replay      -- yesterday's real readings, played back
  | sparse      -- real readings, but only every 10th turn
  | forgetting  -- no sensor; the models see only the opening prompt and the last 10 turns
  deriving DecidableEq, Repr

/-- What is recorded for one run of 100 turns. -/
structure Run where
  /-- Bits of new model text at each turn, measured by compression against the history so far.
  Sensor lines are excluded. -/
  novelty : List ℚ
  /-- Whether each turn uses the current or a recent sensor reading. -/
  grounded : List Bool
  /-- Side-probe forecasts of the next reading (up or down), checked later: right or wrong. -/
  forecasts : List Bool
  deriving Repr

def mean (xs : List ℚ) : ℚ := if xs.length = 0 then 0 else xs.sum / xs.length

/-- Turns `a` to `b - 1`. -/
def window (xs : List ℚ) (a b : ℕ) : List ℚ := (xs.drop a).take (b - a)

/-- A run has *collapsed* if, from some turn `t ≥ 10`, the 10-turn average novelty stays below a
quarter of the opening average (turns 0–9) for 20 turns in a row. -/
def collapsed (r : Run) : Bool :=
  let base := mean (window r.novelty 0 10)
  (List.range r.novelty.length).any fun t =>
    decide (10 ≤ t) && decide (t + 20 ≤ r.novelty.length) &&
      (List.range 20).all fun i =>
        decide (mean (window r.novelty (t + i - 9) (t + i + 1)) < base / 4)

def collapseCount (rs : List Run) : ℕ := (rs.filter collapsed).length

/-- Average novelty over turns 80–99, averaged across runs. -/
def lateNovelty (rs : List Run) : ℚ := mean (rs.map fun r => mean (window r.novelty 80 100))

def share (bs : List Bool) : ℚ :=
  if bs.length = 0 then 0 else ((bs.filter id).length : ℚ) / bs.length

def groundedShare (rs : List Run) : ℚ := share (rs.flatMap Run.grounded)

def forecastAccuracy (rs : List Run) : ℚ := share (rs.flatMap Run.forecasts)

/-- Novelty on the turns that answer a fresh reading (turns 0, 10, 20, …) divided by novelty on
all other turns, averaged across runs. -/
def readingLift (rs : List Run) : ℚ :=
  let on := rs.flatMap fun r =>
    (List.range r.novelty.length).filterMap fun t => if t % 10 = 0 then r.novelty[t]? else none
  let off := rs.flatMap fun r =>
    (List.range r.novelty.length).filterMap fun t => if t % 10 = 0 then none else r.novelty[t]?
  if mean off = 0 then 0 else mean on / mean off

variable (R : Condition → List Run)

/-- The design: 5 runs per condition, 100 turns each. -/
def WellFormed : Prop := ∀ c, (R c).length = 5 ∧ ∀ r ∈ R c, r.novelty.length = 100

/-- **H1 Starvation.** With no sensor, or a sensor stuck on one reading, at least 4 of 5 runs
collapse. (Part A: both are closed, `closed_le_start`; a closed loop can't improve forever,
`no_endless_improvement`.) -/
def H1 : Prop := 4 ≤ collapseCount (R .closed) ∧ 4 ≤ collapseCount (R .constant)

/-- **H2 Senses keep it alive.** With a live sensor, at most 1 of 5 runs collapses, late novelty is
at least double the no-sensor level, and at least half the turns use the readings.
(Part A: only an open sensor lets what can be told apart grow, `distinguishable_le`.) -/
def H2 : Prop :=
  collapseCount (R .live) ≤ 1 ∧
  2 * lateNovelty (R .closed) ≤ lateNovelty (R .live) ∧
  1 / 2 ≤ groundedShare (R .live)

/-- **H3 Meaning, not randomness.** Forecasts of the next noise reading are right 40–60% of the
time (chance); forecasts of the next live reading are right at least 60% of the time.
(Part A: a closed sensor leaves the system at chance about its world, `closed_blind_chance`.) -/
def H3 : Prop :=
  2 / 5 ≤ forecastAccuracy (R .noise) ∧ forecastAccuracy (R .noise) ≤ 3 / 5 ∧
  3 / 5 ≤ forecastAccuracy (R .live)

/-- **H4 Bits are bits.** A replay of yesterday's real readings does as well as the live sensor:
collapse counts within 1, late novelty within 25%. (Part A counts readings the system hasn't seen;
nothing in it depends on whether they are live.) -/
def H4 : Prop :=
  (collapseCount (R .live) : ℤ) - collapseCount (R .replay) ∈ Set.Icc (-1) 1 ∧
  4 * |lateNovelty (R .replay) - lateNovelty (R .live)| ≤ lateNovelty (R .live)

/-- **H5 Rate matters.** With a reading every 10th turn, the turns answering a reading carry at
least 1.5× the novelty of the others (a sawtooth), and late novelty lands strictly between no sensor
and a live sensor every turn. (Part A: growth is capped by readings per turn, `distinguishable_le`.) -/
def H5 : Prop :=
  3 / 2 ≤ readingLift (R .sparse) ∧
  lateNovelty (R .closed) < lateNovelty (R .sparse) ∧
  lateNovelty (R .sparse) < lateNovelty (R .live)

/-- **H6 Forgetting alone isn't enough** (the weakest hypothesis). With no sensor and only the last
10 turns visible, at least 3 of 5 runs still collapse. (Part A: forgetting adds no readings, so
`closed_le_start` still holds. Whether forgetting *delays* the collapse is a guess, not a theorem.) -/
def H6 : Prop := 3 ≤ collapseCount (R .forgetting)

/-- Every hypothesis is a decidable question: once the log exists, Lean can compute the answer. -/
instance : Decidable (H1 R) := by unfold H1; infer_instance
instance : Decidable (H2 R) := by unfold H2; infer_instance
instance : Decidable (H3 R) := by unfold H3; infer_instance
instance : Decidable (H4 R) := by unfold H4; infer_instance
instance : Decidable (H5 R) := by unfold H5; infer_instance
instance : Decidable (H6 R) := by unfold H6; infer_instance

end SensorExperiment
