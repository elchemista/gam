import GAM.Core.Act
namespace GAM

/-- Newest first. All views are projections of one committed history. -/
abbrev State := List Command

def mandates (g : Genesis) : State → List Mandate
  | [] => [g.root]
  | .commit (.grant _ _ child) :: s => child :: mandates g s
  | _ :: s => mandates g s

def spent : State → Nat
  | [] => 0
  | .commit (.admit r) :: s => spent s + r.cost
  | _ :: s => spent s

def policyLimit (g : Genesis) : State → Nat
  | [] => g.root.ceiling
  | .commit (.restrict _ limit) :: _ => limit
  | _ :: s => policyLimit g s

def Active (s : State) (m : Mandate) : Prop :=
  s.any (fun
    | .commit (.revoke _ revoked) => (m.id :: m.ancestors).contains revoked.id
    | _ => false) = false
  deriving Decidable

def FreshRequest (s : State) (id : Nat) : Prop :=
  s.any (fun | .commit (.admit r) => r.id == id | _ => false) = false
  deriving Decidable

def Disposes (d : Duty) : Command → Bool
  | .commit (.dispose _ target _) => target == d
  | _ => false

def OpenDuty (s : State) (d : Duty) : Prop :=
  .enable d.cause.scope.executor d.cause ∈ s ∧ s.any (Disposes d) = false
  deriving Decidable

end GAM
