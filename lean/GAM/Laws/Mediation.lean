import GAM.Transition
namespace GAM

/-- At release, an earlier commit exists for the very same request and its guard
held against the evidence, mandate, policy and account at that earlier instant. -/
def Mediation (g : Genesis) (s : State) : Prop :=
  ∀ later before e r, s = later ++ .enable e r :: before →
    e = r.scope.executor ∧ ∃ between atAdmission,
      before = between ++ .commit (.admit r) :: atAdmission ∧ MayAdmit g atAdmission r

theorem mediation (hr : Reachable g s) : Mediation g s := by
  intro later before e r eq
  subst s
  have release := historicalStep hr
  cases release with
  | enable _ _ h =>
    obtain ⟨between, atAdmission, eq⟩ := List.append_of_mem h.1
    refine ⟨h.2.2.1, between, atAdmission, eq, ?_⟩
    rw [eq, ← List.cons_append, ← List.append_assoc] at hr
    cases historicalStep hr with
    | admit _ allowed => exact allowed

end GAM
