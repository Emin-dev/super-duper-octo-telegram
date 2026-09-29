"""Choose an available iOS 27 iPhone and expose its UDID to GitHub Actions."""
import json
import os
import subprocess

devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"]))
phones = [device for runtime, entries in devices["devices"].items()
          if "iOS-27" in runtime for device in entries if device["name"].startswith("iPhone")]
if not phones:
    raise SystemExit("This runner has no available iOS 27 iPhone simulator.")
phone = sorted(phones, key=lambda device: ("Pro" not in device["name"], device["name"]))[0]
print(f"Testing on {phone['name']} ({phone['udid']})", flush=True)
if phone["state"] != "Booted":
    subprocess.run(["xcrun", "simctl", "boot", phone["udid"]], check=True)
subprocess.run(["xcrun", "simctl", "bootstatus", phone["udid"], "-b"], check=True)
with open(os.environ["GITHUB_ENV"], "a") as output:
    output.write(f"TEST_SIMULATOR_ID={phone['udid']}\n")
