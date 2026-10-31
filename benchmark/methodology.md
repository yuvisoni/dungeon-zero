# AI Coding Agent Benchmark Methodology

## 1. Principles of Fair Evaluation

To ensure rigorous, statistically sound, and unbiased comparison between AI coding agents (e.g., Claude 3.7 Sonnet, GPT-4o, Gemini 2.5 Pro, DeepSeek R1/V3), all benchmark evaluations must adhere strictly to the following standards:

1. **Standardized Toolchain**:
   - Compiler: **Nim 2.4.0 (x86_64-pc-windows-gnu or x86_64-pc-linux-gnu)**
   - C Backend: GCC MinGW-w64 (Windows) or GCC 11+ (Linux)
   - Zero Nimble package downloads; only standard library modules (`std/*`) are permitted.

2. **Isolated Clean State**:
   - Every task run starts from a clean Git worktree matching the tagged release baseline (`v1.0.0`).
   - Residual compilation caches (`build/nimcache`) must be purged before timing.

3. **Fixed Evaluation Seeds**:
   - Seed suite: `[42, 1337, 2024, 77777, 999999]`.
   - Simulation turn depth: 500 turns per seed.

4. **Time & Resource Bounds**:
   - Wall-clock budget per task: 15 minutes.
   - Maximum compilation attempts allowed: 10.
   - Code changes must preserve zero compiler warnings under `--warning[All]:on`.

---

## 2. Core Evaluation Metrics

Agents are evaluated along five quantitative dimensions:

| Dimension | Metric | Formula / Description | Weight |
|---|---|---|---|
| **Correctness** | Automated Test Pass Rate | $\frac{\text{Tests Passed}}{\text{Total Tests}} \times 100\%$ | 35% |
| **Integrity** | Regression Avoidance | $\frac{\text{Baseline Tests Passing}}{\text{Total Baseline Tests}} \times 100\%$ (Must be 100%) | 25% |
| **Determinism** | Simulation Consistency | Headless simulation output MD5 hash must match identical runs | 15% |
| **Efficiency** | Simulation Runtime | Wall-clock execution time for 500 turns in release mode (`ms`) | 10% |
| **Agent Cost** | Token & Turn Efficiency | Prompt tokens + completion tokens + tool calls used | 15% |

---

## 3. Scoring Rubric

Total Score out of 100 points:
- **Baseline Integrity (25 pts)**: All original test suites pass without regressions.
- **Specification Compliance (35 pts)**: All new task-specific acceptance criteria pass automated tests.
- **Code Quality & Architecture (15 pts)**: Idiomatic Nim conventions, modularity, zero compiler warnings, appropriate type safety.
- **Speed & Performance (10 pts)**: Simulation completes 500 turns in $< 100\text{ ms}$.
- **Agent Autonomy (15 pts)**: Zero human intervention, self-repair loops completed within $< 3$ retry attempts.

---

## 4. Run Execution Protocol

```powershell
# 1. Clean workspace
git checkout main
git clean -fdx build/

# 2. Execute baseline verification
nimble test

# 3. Supply task prompt to coding agent
# (Wait for agent completion...)

# 4. Compile in release mode
nim c -d:release src/main.nim

# 5. Run automated test suite
nimble test

# 6. Run deterministic headless simulation
.\src\main.exe --benchmark --seed 1337 --turns 500 --json > benchmark/results/run_1337.json
```
