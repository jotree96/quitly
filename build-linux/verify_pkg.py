#!/usr/bin/env python3
"""Liest das gebaute .pkg zurück und prüft jede Schicht gegen die Quelle."""

import gzip
import hashlib
import io
import os
import struct
import sys
import zlib
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

PKG = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "dist", "Quitly-1.0.0.pkg")
OUT = "/tmp/quitly-verify"

fails = []


def check(label, ok, detail=""):
    print(("  OK   " if ok else "  FEHL ") + label + (("  " + detail) if detail else ""))
    if not ok:
        fails.append(label)


data = open(PKG, "rb").read()
magic, hsize, version, toc_c_len, toc_u_len, cksum_alg = struct.unpack(">4sHHQQI", data[:28])
check("xar-Header magic", magic == b"xar!", magic.decode(errors="replace"))
check("xar-Headergröße 28", hsize == 28, str(hsize))
check("xar-Version 1", version == 1, str(version))
check("Prüfsummenverfahren sha1", cksum_alg == 1, str(cksum_alg))

toc_c = data[hsize:hsize + toc_c_len]
toc = zlib.decompress(toc_c)
check("TOC dekomprimiert, Länge stimmt", len(toc) == toc_u_len, "%d" % len(toc))

heap = data[hsize + toc_c_len:]
check("Heap-Prüfsumme == sha1(komprimierte TOC)",
      heap[:20] == hashlib.sha1(toc_c).digest())

root = ET.fromstring(toc)
toc_el = root.find("toc")

os.makedirs(OUT, exist_ok=True)


def walk(el, prefix=""):
    for f in el.findall("file"):
        name = f.find("name").text
        typ = f.find("type").text
        path = prefix + name
        if typ == "directory":
            print("  dir   %s/" % path)
            walk(f, path + "/")
        else:
            d = f.find("data")
            off = int(d.find("offset").text)
            length = int(d.find("length").text)
            size = int(d.find("size").text)
            enc = d.find("encoding").get("style")
            blob = heap[off:off + length]
            want = d.find("archived-checksum").text
            got = hashlib.sha1(blob).hexdigest()
            check("Datei %s (%d B, %s)" % (path, size, enc),
                  got == want and len(blob) == length and size == length)
            open(os.path.join(OUT, name), "wb").write(blob)


print("\n== xar-Struktur ==")
walk(toc_el)

print("\n== Distribution / PackageInfo ==")
dist = open(os.path.join(OUT, "Distribution"), "rb").read().decode()
pi = open(os.path.join(OUT, "PackageInfo"), "rb").read().decode()
ET.fromstring(dist)
pi_root = ET.fromstring(pi)
check("Distribution ist wohlgeformtes XML", True)
check("PackageInfo ist wohlgeformtes XML", True)
check("pkg-ref zeigt auf quitly.pkg", "#quitly.pkg" in dist)
check("install-location /", pi_root.get("install-location") == "/")
check("auth root", pi_root.get("auth") == "root")
check("preinstall + postinstall registriert",
      '<preinstall file="preinstall"/>' in pi and '<postinstall file="postinstall"/>' in pi)

print("\n== Payload (cpio) ==")
payload = gzip.decompress(open(os.path.join(OUT, "Payload"), "rb").read())


def read_cpio(buf):
    pos = 0
    out = []
    while True:
        hdr = buf[pos:pos + 76]
        if len(hdr) < 76:
            break
        fields = hdr.decode("ascii")
        magic = fields[0:6]
        if magic != "070707":
            raise SystemExit("cpio: falsches magic bei %d: %r" % (pos, magic))
        mode = int(fields[18:24], 8)
        mtime = int(fields[48:59], 8)
        namesize = int(fields[59:65], 8)
        filesize = int(fields[65:76], 8)
        pos += 76
        name = buf[pos:pos + namesize - 1].decode("utf-8")
        pos += namesize
        body = buf[pos:pos + filesize]
        pos += filesize
        if name == "TRAILER!!!":
            break
        out.append((name, mode, filesize, body))
    return out


entries = read_cpio(payload)
check("cpio lesbar, Trailer gefunden", True, "%d Einträge" % len(entries))

import stat as statmod
names = {e[0] for e in entries}
must = [
    "./Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon",
    "./Applications/Hammerspoon.app/Contents/Info.plist",
    "./Library/Application Support/Quitly/window_overview.lua",
    "./Library/Application Support/Quitly/welcome.lua",
    "./Library/Application Support/Quitly/init.lua",
    "./Library/Application Support/Quitly/uninstall.sh",
]
for m in must:
    check("enthält %s" % m, m in names)

links = [e for e in entries if statmod.S_ISLNK(e[1])]
check("Symlinks erhalten", len(links) == 11, "%d gefunden" % len(links))
for name, mode, size, body in links[:3]:
    print("        %s -> %s" % (name, body.decode()))

binmode = [e for e in entries if e[0].endswith("/MacOS/Hammerspoon")][0][1]
check("Hammerspoon-Binary ist ausführbar", bool(binmode & 0o111), oct(binmode))

src_lua = open(os.path.join(REPO, "src", "payload", "window_overview.lua"), "rb").read()
pkg_lua = [e[3] for e in entries if e[0].endswith("Quitly/window_overview.lua")][0]
check("window_overview.lua byte-identisch zur Quelle", src_lua == pkg_lua)

print("\n== Scripts (cpio) ==")
scripts = read_cpio(gzip.decompress(open(os.path.join(OUT, "Scripts"), "rb").read()))
smap = {e[0]: e for e in scripts}
for s in ("./preinstall", "./postinstall"):
    check("%s vorhanden" % s, s in smap)
    if s in smap:
        check("%s hat Modus 0755" % s, (smap[s][1] & 0o777) == 0o755, oct(smap[s][1] & 0o777))
        check("%s beginnt mit Shebang" % s, smap[s][3].startswith(b"#!/bin/bash"))

print("\n== Bom ==")
bom = open(os.path.join(OUT, "Bom"), "rb").read()
check("BOMStore-Magic", bom[:8] == b"BOMStore", bom[:8].decode(errors="replace"))

print("\n" + ("ALLES GRÜN" if not fails else "FEHLER: " + ", ".join(fails)))
sys.exit(1 if fails else 0)
