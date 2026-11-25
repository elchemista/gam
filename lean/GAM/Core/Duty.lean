import GAM.Core.Evidence
namespace GAM
open Lean

/-- Enabling an attempt incurs a reconciliation duty for this exact request. -/
structure Duty where
  cause : Request
  deriving DecidableEq, Repr, FromJson, ToJson

inductive Basis
  | observed (outcome : Outcome)
  | acceptLoss
  deriving DecidableEq, Repr, FromJson, ToJson

end GAM
