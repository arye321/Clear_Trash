"""Run against Factorio 1.1 in an isolated data directory; never save over a user map.

python tests/run.py --factorio PATH [--save EXISTING_1_1_SAVE]
An optional save with a player also exercises the real GUI event handlers.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--factorio", required=True, type=Path)
parser.add_argument("--save", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
runtime = root / ".test-runtime"
for name in ("saves", "scenarios", "archive", "temp", "script-output"):
    (runtime / name).mkdir(parents=True, exist_ok=True)
mod = runtime / "mods" / "Clear_Trash"
mod.mkdir(parents=True, exist_ok=True)
for name in ("info.json", "control.lua"):
    shutil.copy2(root / name, mod / name)
for name in ("scripts", "locale", "tests"):
    shutil.copytree(root / name, mod / name, dirs_exist_ok=True)
with (mod / "control.lua").open("a", encoding="utf-8") as file:
    file.write('\nrequire("tests.integration")\n')
(runtime / "mods" / "mod-list.json").write_text(json.dumps({"mods": [
    {"name": "base", "enabled": True},
    {"name": "Clear_Trash", "enabled": True}
]}), encoding="utf-8")
config = runtime / "config.ini"
data = args.factorio.resolve().parents[2] / "data"
config.write_text(
    "[path]\nread-data=" + data.as_posix()
    + "\nwrite-data=" + runtime.as_posix()
    + "\n[general]\ncheck-updates=false\n", encoding="utf-8")
settings = runtime / "map-gen-settings.json"
settings.write_text(json.dumps({"width": 64, "height": 64, "water": 0,
    "peaceful_mode": True, "autoplace_controls": {}}), encoding="utf-8")
common = [str(args.factorio.resolve()), "--config", str(config),
          "--mod-directory", str(runtime / "mods")]

def run(arguments, require_gui=False):
    result = subprocess.run(common + arguments, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, encoding="utf-8", errors="replace")
    print(result.stdout)
    if result.returncode or "[Clear_Trash tests] COMPLETE" not in result.stdout:
        raise SystemExit("Factorio integration tests failed")
    if require_gui and "PASS: real player GUI handlers" not in result.stdout:
        raise SystemExit("The supplied save must contain a player for GUI checks")

run(["--create", str(runtime / "test-map.zip"), "--map-gen-settings", str(settings)])
if args.save:
    run(["--benchmark", str(args.save.resolve()), "--benchmark-ticks", "1",
         "--benchmark-runs", "1"], require_gui=True)
