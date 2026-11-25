import GAM.Transition
namespace GAM

private def accept (s : State) (c : Command) (p : Prop) [Decidable p] : Option State :=
  if p then some (c :: s) else none

def step (g : Genesis) (s : State) (c : Command) : Option State :=
  match c with
  | .attest a (.consent r) => accept s c (a = g.approver ∧ r.scope.domain = g.root.scope.domain)
  | .attest a (.receipt r _) => accept s c (a = g.observer ∧ .enable r.scope.executor r ∈ s)
  | .commit (.admit r) => accept s c (MayAdmit g s r)
  | .commit (.grant a p child) => accept s c (MayGrant g s a p child)
  | .commit (.revoke a m) => accept s c (a = g.controller ∧ m ∈ mandates g s ∧ Active s m)
  | .commit (.restrict a n) => accept s c (a = g.controller ∧ n ≤ policyLimit g s)
  | .commit (.dispose a d b) => accept s c (OpenDuty s d ∧ Justifies g s a d b)
  | .enable e r => accept s c (MayEnable g s e r)

theorem step_iff : step g s c = some t ↔ Step g s c t := by
  constructor
  · intro h
    unfold step at h
    split at h <;> unfold accept at h <;> split at h <;> simp_all
    all_goals subst t <;> constructor <;> simp_all
  · intro h
    cases h <;> simp_all [step, accept]

/-- Strict replay returns a final state only if the Genesis and every command are valid. -/
def replay (g : Genesis) (commands : List Command) : Option State :=
  if g.Valid then commands.foldlM (step g) [] else none

/-- Relational interpretation of a list in input order. -/
inductive Trace (g : Genesis) : State → List Command → State → Prop
  | nil : Trace g s [] s
  | cons : Step g s c mid → Trace g mid cs t → Trace g s (c :: cs) t

theorem fold_iff_trace (s : State) (cs : List Command) :
    cs.foldlM (step g) s = some t ↔ Trace g s cs t := by
  induction cs generalizing s with
  | nil =>
    constructor
    · intro h
      simp at h
      subst t
      exact .nil
    · intro h
      cases h
      rfl
  | cons c cs ih =>
    constructor
    · intro h
      cases hs : step g s c with
      | none => simp [List.foldlM_cons, hs] at h
      | some mid =>
        exact .cons (step_iff.mp hs) ((ih mid).mp (by simpa [List.foldlM_cons, hs] using h))
    · intro h
      cases h with
      | cons hs tail =>
        simpa [List.foldlM_cons, step_iff.mpr hs] using (ih _).mpr tail

theorem replay_iff : replay g cs = some s ↔ g.Valid ∧ Trace g [] cs s := by
  by_cases h : g.Valid <;> simp [replay, h, fold_iff_trace]

theorem Trace.reachable (h : Trace g start cs s) (initial : Reachable g start) :
    Reachable g s := by
  induction h with
  | nil => exact initial
  | cons step _ ih => exact ih (.next initial step)

/-- Interactive processing records one decision per command and continues after rejection. -/
def attempt (g : Genesis) (acc : State × Array Bool) (c : Command) : State × Array Bool :=
  match step g acc.1 c with
  | some t => (t, acc.2.push true)
  | none => (acc.1, acc.2.push false)

def process (g : Genesis) (cs : List Command) : Option (State × Array Bool) :=
  if g.Valid then some (cs.foldl (attempt g) ([], #[])) else none

private theorem attemptsReachable (cs : List Command) (acc : State × Array Bool)
    (hr : Reachable g acc.1) : Reachable g (cs.foldl (attempt g) acc).1 := by
  induction cs generalizing acc with
  | nil => exact hr
  | cons c cs ih =>
    apply ih
    cases h : step g acc.1 c with
    | none => simpa [attempt, h] using hr
    | some t => simpa [attempt, h] using Reachable.next hr (step_iff.mp h)

theorem processReachable (h : process g cs = some result) : Reachable g result.1 := by
  unfold process at h
  split at h
  · cases h
    apply attemptsReachable
    exact .genesis (by assumption)
  · contradiction

end GAM
