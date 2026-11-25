import GAM.Core.Mandate
namespace GAM
open Lean

/-- Consent names the complete candidate, including the mandate and cost. -/
structure Request where
  id : Nat
  proposer : String
  mandate : Mandate
  scope : Scope
  cost : Nat
  deriving DecidableEq, Repr, FromJson, ToJson

inductive Outcome | succeeded | failed
  deriving DecidableEq, Repr, FromJson, ToJson

inductive Evidence
  | consent (request : Request)
  | receipt (request : Request) (outcome : Outcome)
  deriving DecidableEq, Repr, FromJson, ToJson

end GAM
