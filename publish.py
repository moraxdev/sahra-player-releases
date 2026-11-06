#!/usr/bin/env python3
"""Adds a build to the update feed.
  publish.py android <apk> <versionCode> <version> [--force] [--min N] [--notes TEXT]
  publish.py windows <exe> <build> <version> --key update-key.pem [--force] [--min N] [--notes TEXT]
"""
import argparse, hashlib, json, os, shutil
BASE = "https://raw.githubusercontent.com/moraxdev/sahra-player-releases/main/"
a = argparse.ArgumentParser()
a.add_argument("platform", choices=["android", "windows"]); a.add_argument("file"); a.add_argument("number", type=int); a.add_argument("version")
a.add_argument("--key"); a.add_argument("--force", action="store_true"); a.add_argument("--min", type=int, default=0); a.add_argument("--notes", default="")
o = a.parse_args()
data = open(o.file, "rb").read()
name = f"{o.platform}/sahra-player-{o.version}." + ("apk" if o.platform == "android" else "exe")
os.makedirs(o.platform, exist_ok=True)
for old in os.listdir(o.platform): os.remove(os.path.join(o.platform, old))
shutil.copyfile(o.file, name)
entry = {"version": o.version, "url": BASE + name, "notes": o.notes, "force": o.force}
if o.platform == "android":
    entry.update(code=o.number, minCode=o.min, sha256=hashlib.sha256(data).hexdigest())
else:
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    key = load_pem_private_key(open(o.key, "rb").read(), None)
    entry.update(build=o.number, minBuild=o.min, signature=key.sign(data).hex())
feed = json.load(open("update.json")) if os.path.exists("update.json") else {}
feed[o.platform] = entry
json.dump(feed, open("update.json", "w"), indent=2, ensure_ascii=False)
