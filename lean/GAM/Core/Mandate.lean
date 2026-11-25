import Lean.Data.Json
namespace GAM
open Lean

/-- Installation-local names. A scope freezes the consequence's routing and purpose. -/
structure Scope where
  domain : String
  operation : String
  target : String
  purpose : String
  executor : String
  deriving DecidableEq, Repr, FromJson, ToJson

structure Mandate where
  id : Nat
  holder : String
  scope : Scope
  ceiling : Nat
  /-- Nearest parent first. Kernel-checked at delegation. -/
  ancestors : List Nat
  deriving DecidableEq, Repr, FromJson, ToJson

/-- Fixed constitutional roles and one shared, non-refillable resource account. -/
structure Genesis where
  root : Mandate
  budget : Nat
  controller : String
  approver : String
  observer : String
  reviewer : String
  /-- Principals from whose interest the reviewer is certified independent. -/
  independentOf : List String
  deriving DecidableEq, Repr, FromJson, ToJson

def Genesis.Valid (g : Genesis) : Prop :=
  g.root.ancestors = [] ∧ g.reviewer ∉ g.independentOf
  deriving Decidable

end GAM
