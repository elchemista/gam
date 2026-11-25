import GAM.State
namespace GAM

def MayAdmit (g : Genesis) (s : State) (r : Request) : Prop :=
  r.mandate ∈ mandates g s ∧ Active s r.mandate ∧ r.proposer = r.mandate.holder ∧
  r.scope = r.mandate.scope ∧ r.cost ≤ r.mandate.ceiling ∧ r.cost ≤ policyLimit g s ∧
  spent s + r.cost ≤ g.budget ∧ FreshRequest s r.id ∧
  .attest g.approver (.consent r) ∈ s
  deriving Decidable

def MayGrant (g : Genesis) (s : State) (actor : String) (p c : Mandate) : Prop :=
  p ∈ mandates g s ∧ Active s p ∧ actor = p.holder ∧
  (mandates g s).all (fun m => m.id != c.id) = true ∧
  c.ancestors = p.id :: p.ancestors ∧ c.scope = p.scope ∧ c.ceiling ≤ p.ceiling
  deriving Decidable

def MayEnable (g : Genesis) (s : State) (executor : String) (r : Request) : Prop :=
  .commit (.admit r) ∈ s ∧ Active s r.mandate ∧ executor = r.scope.executor ∧
  r.cost ≤ policyLimit g s ∧ .enable executor r ∉ s
  deriving Decidable

def Outcome.opposite : Outcome → Outcome
  | .succeeded => .failed
  | .failed => .succeeded

def Justifies (g : Genesis) (s : State) (actor : String) (d : Duty) : Basis → Prop
  | .observed o => .attest g.observer (.receipt d.cause o) ∈ s ∧
      .attest g.observer (.receipt d.cause o.opposite) ∉ s
  | .acceptLoss => actor = g.reviewer ∧ d.cause.proposer ∈ g.independentOf ∧
      d.cause.scope.executor ∈ g.independentOf

instance (g s actor d b) : Decidable (Justifies g s actor d b) := by
  cases b <;> unfold Justifies <;> infer_instance

/-- A single accepted transition. Each constructor fixes its complete post-state. -/
inductive Step (g : Genesis) (s : State) : Command → State → Prop
  | consent (actor r) (h : actor = g.approver ∧ r.scope.domain = g.root.scope.domain) :
      Step g s (.attest actor (.consent r)) (.attest actor (.consent r) :: s)
  | receipt (actor r o) (h : actor = g.observer ∧ .enable r.scope.executor r ∈ s) :
      Step g s (.attest actor (.receipt r o)) (.attest actor (.receipt r o) :: s)
  | admit (r) (h : MayAdmit g s r) :
      Step g s (.commit (.admit r)) (.commit (.admit r) :: s)
  | grant (a p c) (h : MayGrant g s a p c) :
      Step g s (.commit (.grant a p c)) (.commit (.grant a p c) :: s)
  | revoke (a m) (h : a = g.controller ∧ m ∈ mandates g s ∧ Active s m) :
      Step g s (.commit (.revoke a m)) (.commit (.revoke a m) :: s)
  | restrict (a n) (h : a = g.controller ∧ n ≤ policyLimit g s) :
      Step g s (.commit (.restrict a n)) (.commit (.restrict a n) :: s)
  | enable (e r) (h : MayEnable g s e r) :
      Step g s (.enable e r) (.enable e r :: s)
  | dispose (a d b) (h : OpenDuty s d ∧ Justifies g s a d b) :
      Step g s (.commit (.dispose a d b)) (.commit (.dispose a d b) :: s)

inductive Reachable (g : Genesis) : State → Prop
  | genesis (valid : g.Valid) : Reachable g []
  | next : Reachable g s → Step g s c t → Reachable g t

/-- Zero or more accepted transitions, including from nonempty histories. -/
inductive Runs (g : Genesis) (start : State) : State → Prop
  | refl : Runs g start start
  | next : Runs g start s → Step g s c t → Runs g start t

theorem Step.recorded (h : Step g s c t) : t = c :: s := by cases h <;> rfl

/-- Recover the actual transition at any position with its original pre-state. -/
theorem historicalStep {c : Command} {before later : State}
    (hr : Reachable g (later ++ c :: before)) : Step g before c (c :: before) := by
  induction later with
  | nil =>
    cases hr with
    | next _ hs => cases hs <;> constructor <;> assumption
  | cons _ _ ih =>
    cases hr with
    | next prev hs => cases hs <;> exact ih prev

end GAM
