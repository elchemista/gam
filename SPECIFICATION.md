# GAM Formal · Core profile 0.1

The normative definition of this profile is the Lean relation `GAM.Step`, its types and its admission predicates. A domain governs a family of requests with a fixed operation, target, purpose and executor. Request identity, proposer and cost can vary. The manifesto also describes surfaces and kinds of evidence beyond this profile. [Transition relation](lean/GAM/Transition.lean) · [Core types](lean/GAM/Core/) · [Manifesto](MANIFESTO.md)

## Genesis and history

A Genesis fixes the root mandate, shared budget, policy controller, consent attester, outcome observer and loss reviewer. It lists the principals from whose interests the reviewer is certified independent. Structural validity requires the root to have empty ancestry and excludes the reviewer from that list. The identity of the founders, the authority they hold and the truth of their independence declarations are external premises.

The initial history is empty. An accepted step adds one record. Lean stores the newest record first, so a chronological prefix is a **suffix** of the Lean list. The executable takes commands in chronological order. Issued mandates, revocations, committed spend, the current ceiling and outstanding duties are projections of the recorded history. Mandates and requests are compared by their full structural value. Issued mandate IDs and admitted request IDs are unique within their respective local namespaces. [State projections](lean/GAM/State.lean)

## Transition rules

| Command | Preconditions in the current history | Recorded consequence |
| --- | --- | --- |
| `attest consent` | The signer is the designated approver and the request names the local domain. | Consent to the complete request, including cost, executor and mandate. |
| `commit admit` | The proposer holds a known, active mandate. Scope and consent match the request exactly. The request ID is fresh. Its cost fits the mandate ceiling, current policy ceiling and remaining common budget. | Admit the Act and charge its cost once. |
| `enable` | An Act admitting this exact request is already recorded. The mandate and its ancestors are active, the cost still meets the policy ceiling, the executor matches and there is no previous release. | Release one attempt and open its reconciliation Duty. |
| `attest receipt` | The designated observer reports on a previously enabled request. | Record observed success or failure. Receipts remain admissible after revocation or disposition. |
| `commit dispose` | The Duty is open. Evidence-based closure requires a matching receipt with no contrary receipt in the current history. Accepting a loss requires the designated reviewer and certified independence from both proposer and executor. | Record a closing Act with its cause, actor and basis. |
| `commit grant` | The holder uses a known, active parent and assigns a fresh child ID. The child names the complete parent lineage, inherits the scope and has a ceiling at most equal to the parent's. | Issue a derived mandate against the same account. |
| `commit revoke` | The controller names a known, active mandate. | Revoke its branch for future delegations, admissions and releases. |
| `commit restrict` | The controller selects a ceiling at most equal to the current one. | Record the policy used by subsequent admissions and releases. |

A mandate ceiling applies to one Act. Delegating a ceiling of 60 permits an Act costing up to 60 against the shared account. All descendants compete for the same remaining balance. Charging at admission means that even a later revocation which blocks release leaves the original commitment on the books. Exclusive allocations, refunds and multiple units of account would require additional accounting rules.

For internal governance acts such as delegation, recording the Act installs the change. An external effect has two distinct positions in the trace, one admitting the Act and one releasing the attempt. A Duty opens at release, so it already exists if the executor loses contact with the external service. Receipt alone leaves it open. Contradictory receipts recorded before disposition block evidence-based closure. Later observations remain recordable after disposition. Reopening a closed dispute would require an additional transition.

## Verified statements

For every `g` and `s`, the central theorem has the following type.

```lean
theorem fourLaws (hr : Reachable g s) :
    Mediation g s ∧ Authority g s ∧ Causality g s ∧ Responsibility g s
```

The base constructor of `Reachable` requires `g.Valid`. Its inductive constructor requires an admitted `Step`. A law can quantify over positions within the current history or over its future extensions. [The combined proof](lean/GAM/Theorems/Consequences.lean)

| Law | Content of the invariant |
| --- | --- |
| I | Every release has a matching earlier Act. The history can be split at the admission position, where the original mandate, consent, freshness and resource checks held. [Mediation](lean/GAM/Laws/Mediation.lean) |
| II | Every recorded mandate has a finite scope-preserving and ceiling-attenuating derivation from the root. The sum of admitted costs never exceeds the original budget. [Authority](lean/GAM/Laws/Authority.lean) |
| III | Every finite continuation preserves the entire previous history in order, including reasons for admission and subsequent observations. [Causality](lean/GAM/Laws/Causality.lean) |
| IV | Every disposition had a live Duty and a valid basis in its own pre-state. Every extension containing no disposition for an open Duty preserves that Duty. [Responsibility](lean/GAM/Laws/Responsibility.lean) |

The following results specialize those invariants and the transition guards.

| Property | Lean declaration | Scope |
| --- | --- | --- |
| Delegation attenuation and shared budget conservation | `delegationAttenuation`, `budgetConservation` | Arbitrary delegation depth and any number of admissions |
| Consent binding | `consentBinding` | The approver attested to the entire admitted request |
| Cross-domain isolation | `crossDomainIsolation` | The same request cannot be admitted under two Genesis domain names that differ |
| Revocation | `revocationPreservesPast`, `revokedCannotEnable`, `lateReceipt` | Old records survive, release is blocked down the revoked branch and an earlier attempt can still receive a receipt |
| Uncertain outcome | `releaseOpensDuty`, `unresolvedPersists`, `noRepeatedRelease` | A pending attempt keeps its Duty across unrelated changes and has at most one release |
| Independent disposition | `independentDisposition` | With valid Genesis, the loss reviewer differs from both the proposer and executor |
| Governed policy change | `policyChange` | Every effective ceiling change is a recorded restriction by the controller |

## Executable correspondence

`step_iff` proves both directions of `step g s c = some t ↔ Step g s c t` for arbitrary states. `replay_iff` extends the equivalence to a chronological list starting from Genesis. Strict replay returns a state precisely when Genesis is valid and every command in the list is admitted. `replayFourLaws` establishes the laws for the resulting state.

The native command-line program calls `process`. It can accept another command after a rejection, retaining the last accepted state. `processReachable` proves that even a mixed stream of admissions and rejections returns a reachable state. The four laws therefore apply to that state too. [Kernel and trace proofs](lean/GAM/Kernel.lean) · [Executable interface](lean/Main.lean)

## Integration assumptions and coverage

- **Identity and evidence.** The host authenticates each actor and binds its assertion to the exact command and local domain. For admission it authenticates the named proposer. It verifies provenance, the material shown to the approver, and the actual independence of the parties identified by Genesis. The profile treats consent as durable for one identified request. Expiring evidence would require a validity rule at the relevant transition.
- **Ordering and persistence.** Each domain has one committed history. Checking a command and appending its record must be atomic with respect to other writers. Restart must recover the same Genesis and committed history. Forking the account could let two replicas spend the same remaining balance.
- **Execution.** The host releases the external capability only after durable commitment of the release. It must control all routes to the effect and bind the request ID to the real operation. The proof bounds the number of releases for one Act. Exactly-once execution by a remote service depends on its protocol.
- **Coverage.** The profile models one resource, exact-scope delegation, two evidence forms and reconciliation duties. Derived-data confidentiality, erasure, emergency powers, expiry, replacement of the kernel and liability for effects outside the boundary require further semantics and proofs. The proved properties are safety properties. A Duty can stay open indefinitely.

## Relationship to prior models

These comparisons identify specific questions for a future expressiveness study. The machine-checked results in this repository concern GAM traces.

| Model | Point of comparison |
| --- | --- |
| RBAC | Roles associate permissions with organizational functions. A domain could use those assignments to select mandate holders and reviewers, then trace an individual commitment through disposition. [Ferraiolo and Kuhn](https://csrc.nist.gov/pubs/conference/1992/10/13/rolebased-access-controls/final) |
| ABAC | Subject, object, operation and environment attributes can inform an admission predicate. GAM records the position at which the predicate held. [NIST SP 800-162](https://csrc.nist.gov/pubs/sp/800/162/upd2/final) |
| Capability security | An object capability could implement the executor's release. The GAM trace identifies the prior decision justifying delivery. [Miller, Yee and Shapiro](https://cgi.cse.unsw.edu.au/~cs9242/papers/Miller_YS_03.pdf) |
| Authorization logic | Relations among principals can express acting on another's behalf. A GAM mandate derivation also carries scope and spending constraints. [Abadi et al.](https://era.ed.ac.uk/items/d7991443-149c-43f9-9723-e9bc636abcbe) |
| Deontic logic | Obligation provides a point of comparison for a Duty. In this profile each Duty has an identifiable cause in a trace and executable conditions for disposition. [von Wright](https://doi.org/10.1093/mind/LX.237.1) |
