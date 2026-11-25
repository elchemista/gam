"""Run portable GAM vectors against any executable speaking the JSON protocol."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def expand(value, names):
    if isinstance(value, dict):
        if set(value) == {"$ref"}:
            return names[value["$ref"]]
        return {key: expand(item, names) for key, item in value.items()}
    if isinstance(value, list):
        return [expand(item, names) for item in value]
    return value


def read_case(path):
    case = json.loads(path.read_text(encoding="utf-8"))
    names = {}
    for name, value in case.get("bindings", []):
        if name in names:
            raise ValueError(f"duplicate binding {name}")
        names[name] = expand(value, names)
    return expand(case["input"], names), case["expect"]


def check(path, kernel):
    data, expected = read_case(path)
    result = subprocess.run(
        [kernel], input=json.dumps(data), text=True, capture_output=True, check=False
    )
    if "error" in expected:
        if result.returncode == 1 and result.stderr.strip() == expected["error"]:
            return
        raise ValueError(f"expected {expected}, got exit {result.returncode}: {result.stderr}")
    if result.returncode:
        raise ValueError(f"kernel returned {result.returncode}: {result.stderr.strip()}")
    actual = json.loads(result.stdout)
    if json.dumps(actual, sort_keys=True) != json.dumps(expected, sort_keys=True):
        raise ValueError(f"expected {expected}, got {actual}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cases", nargs="*", type=Path)
    parser.add_argument("--kernel", default=str(ROOT / "lean/.lake/build/bin/gam-run"))
    parser.add_argument("--expand", metavar="CASE", type=Path,
                        help="print the self-contained kernel input for a single vector")
    args = parser.parse_args()
    if args.expand:
        print(json.dumps(read_case(args.expand)[0], indent=2, ensure_ascii=False))
        return 0
    paths = args.cases or sorted(ROOT.glob("conformance/*/*.json")) + sorted(ROOT.glob("examples/*/*.json"))
    failures = 0
    for path in paths:
        try:
            check(path, args.kernel)
            print(f"ok  {os.path.relpath(path)}")
        except (ValueError, OSError, KeyError) as error:
            print(f"FAIL  {path}: {error}", file=sys.stderr)
            failures += 1
    print(f"{len(paths) - failures}/{len(paths)} passed")
    return int(failures > 0 or not paths)


if __name__ == "__main__":
    sys.exit(main())
