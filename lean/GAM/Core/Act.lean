import GAM.Core.Duty
namespace GAM
open Lean

/-- Entries of this type become Acts only upon successful commit. -/
inductive Act
  | admit (request : Request)
  | grant (actor : String) (parent child : Mandate)
  | revoke (actor : String) (mandate : Mandate)
  | restrict (actor : String) (limit : Nat)
  | dispose (actor : String) (duty : Duty) (basis : Basis)
  deriving DecidableEq, Repr, FromJson, ToJson

inductive Command
  | commit (act : Act)
  | attest (actor : String) (fact : Evidence)
  | enable (executor : String) (request : Request)
  deriving DecidableEq, Repr, FromJson, ToJson

end GAM
