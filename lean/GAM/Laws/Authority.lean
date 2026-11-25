import GAM.Transition
namespace GAM

/-- A finite lineage, with the same scope and a non-increasing per-act ceiling. -/
inductive Derived (root : Mandate) : Mandate → Prop
  | rootMandate : Derived root root
  | child : Derived root p → c.ancestors = p.id :: p.ancestors →
      c.scope = p.scope → c.ceiling ≤ p.ceiling → Derived root c

def Authority (g : Genesis) (s : State) : Prop :=
  (∀ m ∈ mandates g s, Derived g.root m) ∧ spent s ≤ g.budget

theorem authority (hr : Reachable g s) : Authority g s := by
  induction hr with
  | genesis _ => simp [Authority, mandates, spent, Derived.rootMandate]
  | next _ hs ih =>
    obtain ⟨lineage, budget⟩ := ih
    cases hs with
    | grant a p c h =>
      obtain ⟨parent, _, _, _, ancestry, scope, limit⟩ := h
      refine ⟨?_, budget⟩
      intro m hm
      rcases List.mem_cons.mp hm with rfl | old
      · exact .child (lineage p parent) ancestry scope limit
      · exact lineage m old
    | admit r h =>
      obtain ⟨_, _, _, _, _, _, withinBudget, _⟩ := h
      exact ⟨lineage, withinBudget⟩
    | _ => exact ⟨lineage, budget⟩

end GAM
