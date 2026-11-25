# Governed Act Model

[![Core laws proved in Lean 4](docs/badges/lean-laws.svg)](lean/GAM/Theorems/Consequences.lean)
[![Kernel step and replay verified](docs/badges/kernel.svg)](lean/GAM/Kernel.lean)

The Governed Act Model (GAM) describes how a system turns a proposal into an authorized consequence and remains accountable for the outcome. A person, a service or an AI agent can make the proposal. The model applies wherever a domain controls the power to act.

A refund illustrates the four forms. A **Mandate** gives a merchant the right to refund an order within a limit. **Evidence** establishes what the customer approved. An **Act** records the exact refund and commits the funds before the executor can contact the bank. If the connection drops after submission, a **Duty** keeps the case open. A later receipt can support a closing decision, even after the mandate has been revoked. [Read the manifesto](MANIFESTO.md) · [Original publication](https://spectre.guide/en/governed-act-model)

## What Lean proves

For every valid Genesis and every finite sequence of admitted transitions in the reference profile, **all four laws hold together**. The proof covers arbitrary trace lengths. Two further theorems connect the executable kernel to the specification, first for one transition and then for a whole trace. [Combined theorem](lean/GAM/Theorems/Consequences.lean) · [Kernel correspondence](lean/GAM/Kernel.lean)

| Manifesto law | What you can recover or check in a reachable history |
| --- | --- |
| I. Mediate everything that matters | For every release to an executor, find the earlier Act for that exact request and verify its admission conditions at that earlier point. |
| II. Authority does not grow | Trace every mandate back to Genesis through delegations with the same scope and non-increasing ceilings. Add up every committed cost and stay within the original budget. |
| III. Causality cannot be rewritten | Take any later reachable continuation and recover the entire earlier history in order. |
| IV. Duty does not extinguish itself | Find the evidence or independent authority that justified each disposition. Follow an open Duty across any interval that lacks a disposition for it. |

The profile models one domain, one shared account and one family of scoped operations per Genesis. It verifies decisions about release. A deployment must also authenticate identities, commit decisions durably and control every path to the external effect. [Formal scope and integration assumptions](SPECIFICATION.md)

### What the order of events changes

**A valid Act can later be refused release.** Suppose the kernel admits a refund of 50 under a ceiling of 100. If the controller lowers the ceiling to 20 before release, the executor is refused. The history still records a valid admission and 50 units committed. The executor received no capability, so no reconciliation Duty opened. [Runnable policy trace](conformance/adversarial/policy.json)

**The same two receipts can leave a Duty open or closed.** Suppose the bank reports success and later reports failure for the same refund. If both receipts arrive before disposition, the conflict blocks evidence-based closure. If the success receipt justified a closing Act before the failure receipt arrived, the kernel records the late contradiction and keeps the Duty closed. The proof checks the justification available at the time of closure. Reopening a dispute would require an explicit transition. [Duty law](lean/GAM/Laws/Responsibility.lean) · [Receipt and disposition rules](lean/GAM/Transition.lean)

## Build and run

Use Lean 4.36.0, Lake, Make and Python 3. From a fresh checkout with Elan installed, Lake selects the version pinned in `lean/lean-toolchain`. In the supplied workspace, Make also recognizes the local distribution in `lean/.toolchain`. The formal development uses Lean's bundled libraries. [Lean installation guide](https://lean-lang.org/install/)

From the repository root, compile the kernel, check the proofs and run every conformance vector and example.

```sh
make check
```

To see the payment example run through the native executable, use the following command.

```sh
python3 conformance/run.py --expand examples/payments/late_receipt.json | lean/.lake/build/bin/gam-run
```

```json
{"accepted":[true,true,true,true,true,true],"openDuties":[],"policyLimit":100,"spent":50}
```

The six decisions are consent, admission, release, revocation, receipt and disposition. The final record closes the Duty. The 50 units committed at admission remain in the account history. Other runnable examples cover [delegation](examples/delegation/chain.json), [multiple agents sharing a budget](examples/multi_agent/shared_budget.json) and [a request crossing a domain boundary](examples/distributed/foreign_act.json).

## Repository guide

| Start here | Contents |
| --- | --- |
| [Manifesto](MANIFESTO.md) | The full English text published on the Spectre site, including the four forms and four laws. |
| [Specification](SPECIFICATION.md) | Genesis, transition rules, proof statements, assumptions and relationship to other governance models. |
| [GAM Formal](lean/GAM/) | Lean definitions, the executable kernel and machine-checked proofs. |
| [Conformance guide](conformance/README.md) | Portable vectors and the protocol for comparing another implementation with the reference kernel. |

GAM defines the model. GAM Formal provides the normative semantics for the profile in this repository. **Spectre** is the engineering application in which GAM originated. **ex_gam** belongs in a separate Elixir/OTP repository. Rust and Go are possible future implementations. Applying the proofs to any runtime requires a correspondence between that runtime's transitions and GAM Formal, together with evidence about the deployment boundary. [GAM in Spectre](https://github.com/elchemista/spectre/blob/83daf2425b73f8249b5ea4579a3605e65cbc5134/docs/GAM.md)
