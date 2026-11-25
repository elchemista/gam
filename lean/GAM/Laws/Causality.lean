import GAM.Transition
namespace GAM

/-- Each future history contains the entire present history in its original order. -/
def Causality (g : Genesis) (s : State) : Prop :=
  ∀ t, Runs g s t → ∃ newRecords, t = newRecords ++ s

theorem causality (g : Genesis) (s : State) : Causality g s := by
  intro t run
  induction run with
  | refl => exact ⟨[], rfl⟩
  | next _ hs ih =>
    obtain ⟨added, rfl⟩ := ih
    exact ⟨_ :: added, hs.recorded⟩

end GAM
