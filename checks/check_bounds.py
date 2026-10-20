# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Hestia's Creations
"""Exact numerical checks of the theorems in THEOREM.md on small random systems.

Every quantity is computed exactly from full joint distributions (no sampling),
so a failed check means the stated inequality is false for that system.

Run: python3 checks/check_bounds.py
"""
import numpy as np
from scipy.integrate import solve_ivp

rng = np.random.default_rng(20261019)
TOL = 1e-9


def H(p):
    p = np.asarray(p, dtype=float).ravel()
    p = p[p > 0]
    return float(-(p * np.log2(p)).sum())


def mi(joint):
    """I(X;Y) in bits from a 2-D joint distribution."""
    return H(joint.sum(1)) + H(joint.sum(0)) - H(joint)


def random_kernel(n_in, n_out):
    k = rng.random((n_in, n_out)) ** 3
    return k / k.sum(1, keepdims=True)


def step(P, Px_given_ws, F, nR):
    """One update S' = F[s, x, r] with fresh uniform randomness r.

    P[w, s] joint of world and state; Px_given_ws[w, s, x] input kernel.
    Returns new joint P'[w, s'] and I(W; X | S) for the ledger check.
    """
    nW, nS = P.shape
    nX = Px_given_ws.shape[2]
    Pwsx = P[:, :, None] * Px_given_ws
    # I(W;X|S) = sum_s P(s) I(W;X | S=s)
    iwx_s = 0.0
    for s in range(nS):
        ps = Pwsx[:, s, :].sum()
        if ps > 0:
            iwx_s += ps * mi(Pwsx[:, s, :] / ps)
    Pn = np.zeros((nW, nS))
    for s in range(nS):
        for x in range(nX):
            for r in range(nR):
                Pn[:, F[s, x, r]] += Pwsx[:, s, x] / nR
    return Pn, iwx_s


def check_ledger_and_fano(trials=400):
    """Theorem 1 (information ledger) and Theorem 2 (Fano ceiling)."""
    worst_ledger = worst_cap = worst_fano = -np.inf
    worst_closed = -np.inf
    for _ in range(trials):
        nW = int(rng.choice([4, 8, 16]))
        B = int(rng.integers(1, 5))
        nS = 2 ** B
        b = int(rng.integers(0, 3))
        nX = 2 ** b
        nR = int(rng.integers(1, 4))
        pw = rng.dirichlet(np.ones(nW))
        P = pw[:, None] * random_kernel(nW, nS)  # S_0 may already know something
        T = 8
        T0 = int(rng.integers(0, T))  # closed from T0 on
        I_prev = mi(P)
        I0 = I_prev
        cum_b = 0.0
        for t in range(T):
            closed = t >= T0
            if closed:
                Px = np.ones((nW, nS, 1))
                F = rng.integers(0, nS, (nS, 1, nR))
            else:
                Px = random_kernel(nW * nS, nX).reshape(nW, nS, nX)
                F = rng.integers(0, nS, (nS, nX, nR))
            P, iwx_s = step(P, Px, F, nR)
            I_now = mi(P)
            # Lemma 1: I(W;S_{t+1}) <= I(W;S_t) + I(W;X_t|S_t)
            worst_ledger = max(worst_ledger, I_now - (I_prev + iwx_s))
            if not closed:
                cum_b += b
            # Theorem 1: I(W;S_t) <= min(B, I_0 + sum b)
            worst_cap = max(worst_cap, I_now - min(B, I0 + cum_b))
            if closed:
                worst_closed = max(worst_closed, I_now - I_prev)
            # Theorem 2: Fano, for the best possible guess (MAP) from S_t
            pe = 1 - P.max(0).sum()
            bound = (H(pw) - I_now - 1) / np.log2(nW)
            worst_fano = max(worst_fano, bound - pe)
            I_prev = I_now
    return {
        "Lemma 1  I(W;S') - [I(W;S) + I(W;X|S)]  (must be <= 0)": worst_ledger,
        "Thm 1    I(W;S_t) - min(B, I_0 + sum b) (must be <= 0)": worst_cap,
        "Thm 1    closed-step change in I(W;S)   (must be <= 0)": worst_closed,
        "Thm 2    Fano bound - MAP error         (must be <= 0)": worst_fano,
    }


def check_pigeonhole(trials=2000):
    """Theorem 3: closed deterministic B-bit system, strict-improvement runs < 2^B."""
    worst_run_excess = -np.inf
    never_stops = 0
    for _ in range(trials):
        B = int(rng.integers(1, 7))
        nS = 2 ** B
        F = rng.integers(0, nS, nS)
        # bias U so that F tends to improve, to make long runs likely
        U = rng.random(nS)
        order = np.argsort(U)
        for i in range(nS - 1):
            if rng.random() < 0.8:
                F[order[i]] = order[i + 1]
        for s0 in range(nS):
            s, run, best = s0, 0, 0
            for t in range(4 * nS):
                s2 = F[s]
                if U[s2] > U[s]:
                    run += 1
                    best = max(best, run)
                else:
                    run = 0
                s = s2
            # after 4*2^B steps we are on the cycle; one more lap must contain a non-increase
            lap_increasing = True
            for _ in range(nS + 1):
                s2 = F[s]
                if not U[s2] > U[s]:
                    lap_increasing = False
                s = s2
            never_stops += lap_increasing
            worst_run_excess = max(worst_run_excess, best - (nS - 1))
    return {
        "Thm 3    longest strict run - (2^B - 1)   (must be <= 0)": worst_run_excess,
        "Thm 3    trajectories improving forever   (must be 0)": never_stops,
    }


def fact_infos(P, n):
    """I(W_i; S) for each independent fact bit W_i (world index bits)."""
    nW, nS = P.shape
    out = []
    for i in range(n):
        bit = (np.arange(nW) >> i) & 1
        j = np.zeros((2, nS))
        np.add.at(j, bit, P)
        out.append(mi(j))
    return np.array(out)


def check_forgetting(trials=150):
    """Theorem 4: sum_i I(W_i;S) <= I(W;S) <= B, and forgotten >= learned - B."""
    worst_sum = worst_ident = worst_law = -np.inf
    demo = None
    for trial in range(trials):
        n = int(rng.integers(3, 7))
        nW = 2 ** n
        B = int(rng.integers(1, 4))
        nS = 2 ** B
        pw = np.full(nW, 1 / nW)  # independent fair fact bits
        shift = trial % 2 == 0
        P = pw[:, None] * np.eye(1, nS, 0)  # start knowing nothing
        K_prev = fact_infos(P, n)
        gained = lost = 0.0
        T = 3 * n
        for t in range(T):
            i = t % n  # observe fact i this step (1 bit, b = 1)
            bit = (np.arange(nW) >> i) & 1
            Px = np.zeros((nW, nS, 2))
            Px[np.arange(nW), :, bit] = 1.0
            if shift:  # shift register: keep last B observations, oldest falls off
                F = np.array([[[((s << 1) | x) & (nS - 1)] for x in range(2)] for s in range(nS)])
                nR = 1
            else:
                nR = 2
                F = rng.integers(0, nS, (nS, 2, nR))
            P, _ = step(P, Px, F, nR)
            K = fact_infos(P, n)
            d = K - K_prev
            gained += d[d > 0].sum()
            lost += -d[d < 0].sum()
            worst_sum = max(worst_sum, K.sum() - mi(P), mi(P) - B)
            K_prev = K
        K_T = K_prev.sum()
        # identity: lost = gained - (K_T - K_0), with K_0 = 0
        worst_ident = max(worst_ident, abs(lost - (gained - K_T)))
        worst_law = max(worst_law, (gained - B) - lost)
        if shift and demo is None and n >= 5:
            demo = (n, B, T, gained, lost)
    return {
        "Thm 4    max(sum I(W_i;S) - I(W;S), I(W;S) - B) (must be <= 0)": worst_sum,
        "Thm 4    |lost - (gained - K_T)|        (must be ~0)": worst_ident,
        "Thm 4    (gained - B) - lost            (must be <= 0)": worst_law,
    }, demo


def check_two_minds(trials=200):
    """Theorem 5: joint knowledge <= I_0 + (b_A + b_B) t; one mind alone can exceed its own budget."""
    worst_joint = -np.inf
    best_B_excess = -np.inf
    for _ in range(trials):
        nW = 8
        BA, BB = 2, 2
        nA, nB = 2 ** BA, 2 ** BB
        nS = nA * nB  # joint state index = a * nB + bstate
        pw = np.full(nW, 1 / nW)
        P = pw[:, None] * np.eye(1, nS, 0)
        bA = 1  # only mind A sees the world; B learns only from A
        I0 = mi(P)
        cum = 0.0
        FA = rng.integers(0, nA, (nA, 2, nB))     # A' = FA[a, x, b]   (A reads B's state)
        FB = rng.integers(0, nB, (nB, nA))        # B' = FB[b, a]      (B reads A's message)
        FB[:, :] = (np.arange(nA)[None, :] % nB)  # make B copy A, so B clearly gains
        for t in range(6):
            i = t % 3
            bit = (np.arange(nW) >> i) & 1
            Px = np.zeros((nW, nS, 2))
            Px[np.arange(nW), :, bit] = 1.0
            F = np.zeros((nS, 2, 1), dtype=int)
            for s in range(nS):
                a, bs = divmod(s, nB)
                for x in range(2):
                    F[s, x, 0] = FA[a, x, bs] * nB + FB[bs, a]
            P, _ = step(P, Px, F, 1)
            cum += bA
            worst_joint = max(worst_joint, mi(P) - (I0 + cum))
            PB = P.reshape(nW, nA, nB).sum(1)
            best_B_excess = max(best_B_excess, mi(PB) - 0.0)  # B's own outside budget is 0
    return {
        "Thm 5    joint I - (I_0 + (bA+bB) t)    (must be <= 0)": worst_joint,
        "Thm 5    mind B's knowledge with b_B=0  (shows > 0 is possible)": best_B_excess,
    }


def check_growth_law():
    """Theorem 6: dA/dt = k A^(1+p): closed forms, doubling-time ratio 2^-p, blow-up time."""
    out = {}
    worst = 0.0
    for p in [-0.4, -0.205, 0.0, 0.143, 0.286, 0.5, 1.0]:
        k, A0 = 0.7, 1.0
        # first doubling time T1 from the closed form
        T1 = np.log(2) / k if p == 0 else (A0 ** -p) * (1 - 2 ** -p) / (p * k)
        horizon = 6 * T1 if p <= 0 else 0.98 * T1 / (1 - 2 ** -p)
        sol = solve_ivp(lambda t, A: k * A ** (1 + p), (0, horizon), [A0],
                        rtol=1e-11, atol=1e-12, dense_output=True)
        ts = np.linspace(0, horizon, 50)
        if p == 0:
            exact = A0 * np.exp(k * ts)
        else:
            exact = (A0 ** -p - p * k * ts) ** (-1 / p)
        worst = max(worst, float(np.max(np.abs(sol.sol(ts)[0] / exact - 1))))
        # successive doubling times shrink (p>0) or grow (p<0) by 2^-p
        times, level = [], A0
        for _ in range(3):
            target = 2 * level
            tt = (A0 ** -p - target ** -p) / (p * k) if p != 0 else np.log(target / A0) / k
            times.append(tt)
            level = target
        d = np.diff([0] + times)
        worst = max(worst, abs(d[1] / d[0] - 2 ** -p), abs(d[2] / d[1] - 2 ** -p))
    out["Thm 6    closed form vs ODE solver, doubling ratio (rel. err, ~0)"] = worst
    # Jones model with E = cA: check that growth exponent p equals lambda (1 - 1/r)
    worst = 0.0
    for r in [0.83, 1.0, 1.4, 2.0, 3.5]:
        for lam in [0.3, 0.5, 1.0]:
            beta = lam / r
            theta, c = 0.5, 2.0
            g = lambda A: A * theta * A ** -beta * (c * A) ** lam  # dA/dt
            A1, A2 = 10.0, 1000.0
            slope = (np.log(g(A2)) - np.log(g(A1))) / (np.log(A2) - np.log(A1))
            worst = max(worst, abs((slope - 1) - lam * (1 - 1 / r)))
    out["Thm 6    Jones model exponent - lam(1-1/r)    (~0)"] = worst
    return out


if __name__ == "__main__":
    results = {}
    results.update(check_ledger_and_fano())
    results.update(check_pigeonhole())
    f, demo = check_forgetting()
    results.update(f)
    results.update(check_two_minds())
    results.update(check_growth_law())
    for k, v in results.items():
        print(f"{k}: {v: .3e}")
    if demo:
        n, B, T, g, l = demo
        print(f"\nForgetting demo (shift register): {n} facts, B={B} bits, {T} steps -> "
              f"learned {g:.2f} bits, forgot {l:.2f} bits, net {g - l:.2f} <= B")
    # pass/fail
    fails = []
    for k, v in results.items():
        if "shows" in k:
            if not v > 0.5:
                fails.append(k)
        elif "~0" in k:
            if abs(v) > 1e-6:
                fails.append(k)
        elif v > TOL:
            fails.append(k)
    print("\nALL CHECKS PASS" if not fails else "FAILED:\n  " + "\n  ".join(fails))
