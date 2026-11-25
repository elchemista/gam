import GAM.Kernel
import GAM.Laws.Authority
import GAM.Laws.Causality
import GAM.Laws.Mediation
import GAM.Laws.Responsibility
namespace GAM

theorem fourLaws (hr : Reachable g s) :
    Mediation g s ∧ Authority g s ∧ Causality g s ∧ Responsibility g s :=
  ⟨mediation hr, authority hr, causality g s, responsibility hr⟩

theorem replayFourLaws (h : replay g cs = some s) :
    Mediation g s ∧ Authority g s ∧ Causality g s ∧ Responsibility g s :=
  let ⟨valid, trace⟩ := replay_iff.mp h
  fourLaws (trace.reachable (.genesis valid))

theorem Derived.bounds (h : Derived root m) :
    m.scope = root.scope ∧ m.ceiling ≤ root.ceiling := by
  induction h with
  | rootMandate => exact ⟨rfl, Nat.le_refl _⟩
  | child _ _ scope limit ih => exact ⟨scope.trans ih.1, Nat.le_trans limit ih.2⟩

theorem budgetConservation (hr : Reachable g s) : spent s ≤ g.budget :=
  (authority hr).2

theorem delegationAttenuation (hr : Reachable g s) (hm : m ∈ mandates g s) :
    m.scope = g.root.scope ∧ m.ceiling ≤ g.root.ceiling :=
  ((authority hr).1 m hm).bounds

theorem consentBinding (h : Step g s (.commit (.admit r)) t) :
    .attest g.approver (.consent r) ∈ s := by
  cases h with
  | admit _ allowed =>
    obtain ⟨_, _, _, _, _, _, _, _, consent⟩ := allowed
    exact consent

theorem domainIsolation (hr : Reachable g s) (h : Step g s (.commit (.admit r)) t) :
    r.scope.domain = g.root.scope.domain := by
  cases h with
  | admit _ allowed =>
    obtain ⟨known, _, _, scope, _⟩ := allowed
    rw [scope, (delegationAttenuation hr known).1]

theorem crossDomainIsolation (origin : Reachable g s) (admitted : Step g s (.commit (.admit r)) t)
    (receiver : Reachable other u) (distinct : g.root.scope.domain ≠ other.root.scope.domain) :
    ¬ Step other u (.commit (.admit r)) v := by
  intro imported
  exact distinct ((domainIsolation origin admitted).symm.trans (domainIsolation receiver imported))

/-- Revoking a mandate or its ancestor bars release from that point on. -/
theorem revokedCannotEnable (revoked : Command.commit (.revoke a m) ∈ s)
    (ancestor : m.id ∈ r.mandate.id :: r.mandate.ancestors) :
    ¬ Step g s (.enable e r) t := by
  intro hs
  cases hs with
  | enable _ _ h =>
    have active := List.any_eq_false.mp h.2.1 _ revoked
    simp [ancestor] at active

theorem revocationPreservesPast (h : Step g s (.commit (.revoke a m)) t) (past : c ∈ s) :
    c ∈ t := h.recorded ▸ List.mem_cons_of_mem _ past

/-- The original attempt suffices to record a late observation, also after revocation. -/
theorem lateReceipt (attempted : Command.enable r.scope.executor r ∈ s) :
    Step g s (.attest g.observer (.receipt r o)) (.attest g.observer (.receipt r o) :: s) :=
  .receipt _ _ _ ⟨rfl, attempted⟩

/-- A successful release always creates an outstanding reconciliation obligation. -/
theorem releaseOpensDuty (hr : Reachable g s) (h : Step g s (.enable e r) t) :
    OpenDuty t ⟨r⟩ := by
  cases h with
  | enable _ _ allowed =>
    obtain ⟨_, _, rfl, _, firstRelease⟩ := allowed
    refine ⟨List.mem_cons_self, ?_⟩
    simp only [List.any_cons, Disposes, Bool.false_or]
    apply List.any_eq_false.mpr
    intro c present closing
    cases c with
    | attest | enable => simp [Disposes] at closing
    | commit a =>
      cases a with
      | dispose actor d b =>
        simp [Disposes] at closing
        subst d
        obtain ⟨later, before, split⟩ := List.append_of_mem present
        have wasOpen := ((responsibility hr).1 later before actor ⟨r⟩ b split).1
        exact firstRelease (split ▸ List.mem_append_right _ (List.mem_cons_of_mem _ wasOpen.1))
      | _ => simp [Disposes] at closing

theorem independentDisposition (valid : g.Valid)
    (h : Step g s (.commit (.dispose a d .acceptLoss)) t) :
    a = g.reviewer ∧ a ≠ d.cause.proposer ∧ a ≠ d.cause.scope.executor := by
  cases h with
  | dispose _ _ _ allowed =>
    obtain ⟨rfl, proposer, executor⟩ := allowed.2
    exact ⟨rfl, fun eq => valid.2 (eq ▸ proposer), fun eq => valid.2 (eq ▸ executor)⟩

theorem noRepeatedRelease (previous : Command.enable e r ∈ s) :
    ¬ Step g s (.enable e r) t := by
  intro hs
  cases hs with
  | enable _ _ h =>
    obtain ⟨_, _, _, _, fresh⟩ := h
    exact fresh previous

/-- Even the policy limit changes only by a controller's recorded restriction. -/
theorem policyChange (h : Step g s c t) (changed : policyLimit g t ≠ policyLimit g s) :
    ∃ n, c = .commit (.restrict g.controller n) ∧ n < policyLimit g s := by
  cases h <;> simp_all [policyLimit]
  omega

end GAM
