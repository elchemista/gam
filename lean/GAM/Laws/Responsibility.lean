import GAM.Transition
namespace GAM

/-- Any interval containing no disposition of this duty preserves it. -/
theorem unresolvedPersists (h : OpenDuty s d) (noClose : later.any (Disposes d) = false) :
    OpenDuty (later ++ s) d :=
  ⟨List.mem_append_right _ h.1, by rw [List.any_append, noClose, h.2]; rfl⟩

/-- Every closing Act has a live cause and its own justification in the prior history. -/
def Responsibility (g : Genesis) (s : State) : Prop :=
  (∀ later before a d b, s = later ++ .commit (.dispose a d b) :: before →
    OpenDuty before d ∧ Justifies g before a d b) ∧
  ∀ d later, OpenDuty s d → later.any (Disposes d) = false → OpenDuty (later ++ s) d

theorem responsibility (hr : Reachable g s) : Responsibility g s := by
  refine ⟨?_, fun _ _ h gap => unresolvedPersists h gap⟩
  intro later before a d b eq
  subst s
  cases historicalStep hr with
  | dispose _ _ _ h => exact h

end GAM
