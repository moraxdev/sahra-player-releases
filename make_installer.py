#!/usr/bin/env python3
"""Wraps the current Windows program file in an installer and adds it to update.json.

  make_installer.py <program.exe> <version> [--key update-key.pem]

Reads app settings from installer.json beside this file. Adds "installer": {url, size,
signature|sha256} to the Windows entry; every other field stays as it is, so versions
already out keep updating exactly as before. Needs makensis (apt install nsis).
"""
import argparse, hashlib, json, os, subprocess, sys
here = os.path.dirname(os.path.abspath(__file__))
os.chdir(here)
cfg = json.load(open("installer.json"))
a = argparse.ArgumentParser()
a.add_argument("file"); a.add_argument("version"); a.add_argument("--key")
o = a.parse_args()
os.makedirs("installers", exist_ok=True)
for old in os.listdir("installers"):
    if old.endswith(".exe"): os.remove(os.path.join("installers", old))
name = f"installers/{cfg['app'].replace(' ', '-')}-Setup-{o.version}.exe"
subprocess.run(["makensis", "-V2", f"-DAPP={cfg['app']}", f"-DEXE={cfg['exe']}", f"-DKEY={cfg['key']}",
                f"-DVERSION={o.version}", f"-DSRC={os.path.abspath(o.file)}", f"-DICON={os.path.abspath(cfg['icon'])}",
                f"-DOUT={os.path.abspath(name)}", "installer.nsi"], check=True)
data = open(name, "rb").read()
entry = {"url": cfg["base"] + name, "size": len(data)}
if o.key:
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    entry["signature"] = load_pem_private_key(open(o.key, "rb").read(), None).sign(data).hex()
else:
    entry["sha256"] = hashlib.sha256(data).hexdigest()
feed_file = cfg.get("feed", "update.json")
feed = json.load(open(feed_file))
target = feed["windows"] if "windows" in feed else feed
if target.get("version") != o.version:
    sys.exit(f"update.json has version {target.get('version')}, not {o.version}; publish the program first.")
target["installer"] = entry
json.dump(feed, open(feed_file, "w"), indent=2, ensure_ascii=False)
print(name, len(data))
