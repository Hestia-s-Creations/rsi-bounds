-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (C) 2026 Hestia's Creations
-- Prints the axioms every Part A theorem depends on. Run: lake env lean Axioms.lean
-- Expected on every line: [propext, Classical.choice, Quot.sound]
import SensorExperiment
open SensorExperiment
#print axioms distinguishable_succ_le
#print axioms distinguishable_le
#print axioms distinguishable_le_memory
#print axioms closed_succ_le
#print axioms closed_le_start
#print axioms correct_guesses_le
#print axioms speed_limit
#print axioms closed_blind_chance
#print axioms no_endless_improvement
#print axioms improving_run_le_states
#print axioms forgotten_eq
#print axioms forgetting_law
#print axioms forgetting_law_facts
#print axioms two_minds
#print axioms feedback_exponent
#print axioms feedback_pos_iff
#print axioms doublingTime_next
#print axioms doublingTime_nth
#print axioms doublings_shrink
#print axioms total_time
