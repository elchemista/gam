import GAM
open GAM Lean

structure Input where
  genesis : Genesis
  commands : List GAM.Command
  deriving FromJson, ToJson

private def openDuties (s : State) : List Nat :=
  s.reverse.filterMap fun
    | .enable _ r => if OpenDuty s ⟨r⟩ then some r.id else none
    | _ => none

/-- An interactive caller can continue after a rejection, retaining its last state. -/
private def run (input : Input) : Except String Json := do
  let g := input.genesis
  let some (state, decisions) := process g input.commands | throw "invalid Genesis"
  return Json.mkObj [
    ("accepted", toJson decisions), ("spent", toJson (spent state)),
    ("openDuties", toJson (openDuties state)), ("policyLimit", toJson (policyLimit g state))]

private def decode (json : Json) : Except String Input := do
  let input : Input ← fromJson? json
  unless toJson input == json do throw "input contains unrecognized fields or values"
  return input

def main (args : List String) : IO UInt32 := do
  let source ← match args with
    | [] => (← IO.getStdin).readToEnd
    | [path] => IO.FS.readFile path
    | _ =>
      IO.eprintln "usage: gam-run [input.json]"
      return 2
  match Json.parse source >>= decode >>= run with
  | .ok result => IO.println result.compress; return 0
  | .error msg => IO.eprintln msg; return 1
