# DUNGEON ZERO — AI Coding Agent Benchmark Harness

## Overview

The **DUNGEON ZERO AI Coding Agent Benchmark** is an empirical evaluation framework designed to benchmark autonomous AI coding agents on real-world systems programming, procedural generation, algorithms, and systems debugging in **Nim 2.4.0**.

Unlike synthetic competitive programming snippets, DUNGEON ZERO tests agent capabilities on an integrated, multi-file codebase with strict contracts:
1. **Zero External Dependencies**: Agent must leverage Nim's standard library and adhere to strict architectural separation.
2. **Deterministic Mechanics**: Game simulations must remain 100% reproducible given fixed PRNG seeds.
3. **Rigorous Verification**: Automated unit tests and headless simulation benchmarks objectively score code correctness, regression avoidance, and execution speed.

---

## Directory Structure

```
benchmark/
├── README.md               # Harness overview, architecture, and scoring guide
├── methodology.md          # Fair evaluation protocol, metrics, and agent requirements
├── tasks/
│   ├── task_01.md          # Feature: Vault & Special Room Generation
│   ├── task_02.md          # Debugging: Diagonal Corner Visibility Occlusion
│   └── task_03.md          # Enemy AI: Cowardly Goblin Flee Mechanic
└── results/
    ├── results_template.json   # Machine-readable output schema
    └── results_template.csv    # Tabular summary schema
```

---

## Evaluation Workflow

Each evaluation run consists of the following phases:

1. **Environment Preparation**:
   - Ensure Nim 2.4.0 is available on system PATH (`nim -v`).
   - Run baseline test suite to ensure pristine test pass rate:
     ```powershell
     nimble test
     ```

2. **Task Assignment**:
   - Present the agent with one task specification from `benchmark/tasks/`.
   - The agent is instructed to plan, modify source files, and add or update corresponding test files.

3. **Validation & Automated Scoring**:
   - Run the task verification test suite.
   - Run the full regression test suite (`nimble test`).
   - Run headless simulation benchmark across benchmark seeds:
     ```powershell
     .\src\main.exe --benchmark --seed 1337 --turns 500 --json
     ```

4. **Metrics Collection**:
   - Record time to solution, total token consumption, compile pass/fail status, test pass rate, and simulation performance in `benchmark/results/`.
