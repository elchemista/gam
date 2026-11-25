# Conformance vectors

Each JSON file specifies a Genesis, a chronological command sequence and its expected result. The suite covers valid traces, invalid inputs and attempts to violate an invariant. It also runs the four application examples. Each vector fixes the decision at every step, including commands following a rejection.

```sh
make check
python3 conformance/run.py conformance/adversarial/cascade.json
python3 conformance/run.py --kernel /path/to/another/implementation
```

## Executable protocol

The runner writes a JSON object with `genesis` and `commands` to the executable's standard input. Every invocation begins with an empty history. Field and constructor names follow the Lean core types. Numbers are natural numbers, textual names are opaque, and object keys must be unique. The reference executable also accepts a path to an expanded JSON file as its only argument. [Core types](../lean/GAM/Core/) · [Executable](../lean/Main.lean)

For well-formed input with a valid Genesis, the executable exits with status 0 and writes one object to standard output.

```json
{"accepted":[true,true,true,false],"spent":50,"openDuties":[1],"policyLimit":100}
```

- `accepted` contains one decision per command in input order. After a rejection, the next command is evaluated against the last accepted history.
- `spent` is the sum of costs committed by admitted Acts.
- `openDuties` lists the request IDs awaiting disposition, in chronological release order.
- `policyLimit` is the current per-Act ceiling.

Undecodable input or an invalid Genesis produces exit status 1 and a diagnostic on standard error. Error vectors specify the expected diagnostic in `expect.error`. A well-formed command refused by a governance rule yields a `false` decision and the program continues.

## Reading or exporting a vector

`bindings` is an ordered list of name-value pairs. An object whose only key is `$ref` expands to the value previously defined by that name. These abbreviations belong to the test format. The kernel receives fully expanded commands. The `description` explains the case, `input` holds the call and `expect` fixes its result.

To inspect exactly what a second implementation would receive, run the following command.

```sh
python3 conformance/run.py --expand conformance/adversarial/self_disposal.json
```

An external adapter can consume the output of `--expand` or implement the protocol for `--kernel`. Passing the vectors demonstrates agreement on the included cases. A proof for every possible trace requires a refinement argument for that implementation.
