#!/usr/bin/env python3
"""
Baut Quitly.pkg (macOS Distribution-Paket) ohne Apple-Werkzeuge.

Erzeugt wird ein flat package: ein xar-Archiv mit
    Distribution
    Resources/welcome.html, Resources/conclusion.html
    quitly.pkg/PackageInfo, Bom, Payload, Scripts

Payload und Scripts sind gzip-komprimierte cpio-Archive im odc-Format,
Bom kommt von mkbom (bomutils).

Voraussetzungen auf dem Build-Rechner (Linux, kein macOS noetig):
  1. Hammerspoon entpackt nach HS_APP, siehe Konstante unten:
       curl -fsSL -o hs.zip \
         https://github.com/Hammerspoon/hammerspoon/releases/download/1.1.1/Hammerspoon-1.1.1.zip
       unzip hs.zip -d /tmp/hs
  2. mkbom aus bomutils gebaut, siehe Konstante MKBOM:
       git clone https://github.com/hogliux/bomutils /tmp/bomutils
       make -C /tmp/bomutils
  3. Dieses Skript aus dem Ordner starten, der payload/, scripts/
     und resources/ enthaelt:
       python3 build_pkg.py
"""

import gzip
import hashlib
import os
import shutil
import stat
import struct
import subprocess
import sys
import time
import zlib
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = "/tmp/quitly-build"
HS_APP = "/tmp/hs/Hammerspoon.app"
MKBOM = "/tmp/bomutils/build/bin/mkbom"

IDENTIFIER = "de.humandigitals.quitly"
VERSION = "1.0.0"
PKG_DIR_NAME = "quitly.pkg"
OUT = os.path.join(HERE, "dist", "Quitly-%s.pkg" % VERSION)

NOW = int(time.time())
ISO = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(NOW))


# --------------------------------------------------------------------------
# cpio (odc / POSIX portable ASCII, magic 070707)
# --------------------------------------------------------------------------

def _cpio_header(name, st, ino, filesize):
    is_dir = stat.S_ISDIR(st.st_mode)
    fields = [
        "070707",
        "%06o" % 0,                       # dev
        "%06o" % (ino & 0o777777),        # ino
        "%06o" % (st.st_mode & 0o777777), # mode inkl. Typbits
        "%06o" % 0,                       # uid  -> root
        "%06o" % 0,                       # gid  -> wheel
        "%06o" % (2 if is_dir else 1),    # nlink
        "%06o" % 0,                       # rdev
        "%011o" % int(st.st_mtime),
        "%06o" % (len(name) + 1),
        "%011o" % filesize,
    ]
    return "".join(fields).encode("ascii")


def _walk_entries(root):
    """('./pfad', absoluter_pfad) in Reihenfolge Eltern vor Kindern."""
    yield ".", root
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames.sort()
        filenames.sort()
        for name in sorted(dirnames + filenames):
            full = os.path.join(dirpath, name)
            rel = "./" + os.path.relpath(full, root)
            yield rel, full


def write_cpio_gz(root, out_path):
    ino = 1
    count = 0
    raw = []
    for rel, full in _walk_entries(root):
        st = os.lstat(full)
        if stat.S_ISLNK(st.st_mode):
            data = os.readlink(full).encode("utf-8")
        elif stat.S_ISREG(st.st_mode):
            with open(full, "rb") as fh:
                data = fh.read()
        else:
            data = b""
        name = rel.encode("utf-8")
        raw.append(_cpio_header(name, st, ino, len(data)))
        raw.append(name + b"\0")
        raw.append(data)
        ino += 1
        count += 1

    trailer = b"".join([
        b"070707",
        b"%06o" % 0, b"%06o" % 0, b"%06o" % 0, b"%06o" % 0, b"%06o" % 0,
        b"%06o" % 1, b"%06o" % 0, b"%011o" % 0, b"%06o" % 11, b"%011o" % 0,
    ])
    raw.append(trailer)
    raw.append(b"TRAILER!!!\0")

    payload = b"".join(raw)
    with open(out_path, "wb") as fh:
        gz = gzip.GzipFile(fileobj=fh, mode="wb", compresslevel=9, mtime=0)
        gz.write(payload)
        gz.close()
    return count


def install_kbytes(root):
    total = 0
    for _rel, full in _walk_entries(root):
        st = os.lstat(full)
        if stat.S_ISREG(st.st_mode) or stat.S_ISDIR(st.st_mode):
            total += ((st.st_size + 4095) // 4096) * 4096
    return total // 1024


# --------------------------------------------------------------------------
# xar
# --------------------------------------------------------------------------

class XarFile:
    def __init__(self, name, src=None, mode=0o644):
        self.name = name
        self.src = src
        self.mode = mode


class XarDir:
    def __init__(self, name, children, mode=0o755):
        self.name = name
        self.children = children
        self.mode = mode


def build_xar(entries, out_path):
    heap = []            # Liste von bytes, beginnend hinter dem Prüfsummenblock
    heap_offset = [20]   # sha1 der komprimierten TOC belegt Offset 0..19
    next_id = [1]

    def render(node, indent):
        pad = " " * indent
        fid = next_id[0]
        next_id[0] += 1
        head = '%s<file id="%d">\n' % (pad, fid)
        head += "%s  <name>%s</name>\n" % (pad, escape(node.name))
        if isinstance(node, XarDir):
            head += "%s  <type>directory</type>\n" % pad
            head += _meta(pad, node.mode)
            for child in node.children:
                head += render(child, indent + 2)
        else:
            with open(node.src, "rb") as fh:
                data = fh.read()
            digest = hashlib.sha1(data).hexdigest()
            offset = heap_offset[0]
            heap.append(data)
            heap_offset[0] += len(data)
            head += "%s  <type>file</type>\n" % pad
            head += _meta(pad, node.mode)
            head += "%s  <data>\n" % pad
            head += "%s    <length>%d</length>\n" % (pad, len(data))
            head += "%s    <offset>%d</offset>\n" % (pad, offset)
            head += "%s    <size>%d</size>\n" % (pad, len(data))
            head += '%s    <encoding style="application/octet-stream"/>\n' % pad
            head += '%s    <extracted-checksum style="sha1">%s</extracted-checksum>\n' % (pad, digest)
            head += '%s    <archived-checksum style="sha1">%s</archived-checksum>\n' % (pad, digest)
            head += "%s  </data>\n" % pad
        head += "%s</file>\n" % pad
        return head

    def _meta(pad, mode):
        return (
            "%s  <mode>0%o</mode>\n" % (pad, mode)
            + "%s  <uid>0</uid>\n" % pad
            + "%s  <gid>0</gid>\n" % pad
            + "%s  <atime>%s</atime>\n" % (pad, ISO)
            + "%s  <mtime>%s</mtime>\n" % (pad, ISO)
            + "%s  <ctime>%s</ctime>\n" % (pad, ISO)
        )

    body = "".join(render(e, 2) for e in entries)
    toc = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        "<xar>\n"
        "  <toc>\n"
        "    <creation-time>%s</creation-time>\n"
        '    <checksum style="sha1">\n'
        "      <offset>0</offset>\n"
        "      <size>20</size>\n"
        "    </checksum>\n"
        "%s"
        "  </toc>\n"
        "</xar>\n" % (ISO, body)
    ).encode("utf-8")

    toc_compressed = zlib.compress(toc, 9)
    toc_sha1 = hashlib.sha1(toc_compressed).digest()

    header = struct.pack(
        ">4sHHQQI",
        b"xar!",
        28,                   # Headergröße
        1,                    # Version
        len(toc_compressed),
        len(toc),
        1,                    # Prüfsummenverfahren: sha1
    )

    with open(out_path, "wb") as fh:
        fh.write(header)
        fh.write(toc_compressed)
        fh.write(toc_sha1)
        for chunk in heap:
            fh.write(chunk)


# --------------------------------------------------------------------------
# Aufbau
# --------------------------------------------------------------------------

def copy_tree(src, dst):
    shutil.copytree(src, dst, symlinks=True)


def main():
    if os.path.exists(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)

    root = os.path.join(WORK, "root")
    scripts = os.path.join(WORK, "scripts")
    flat = os.path.join(WORK, "flat")
    pkgdir = os.path.join(flat, PKG_DIR_NAME)
    resources = os.path.join(flat, "Resources")
    for d in (root, scripts, pkgdir, resources):
        os.makedirs(d)

    # ---- Payload ----------------------------------------------------------
    apps = os.path.join(root, "Applications")
    os.makedirs(apps)
    copy_tree(HS_APP, os.path.join(apps, "Hammerspoon.app"))

    support = os.path.join(root, "Library", "Application Support", "Quitly")
    os.makedirs(support)
    for name in ("window_overview.lua", "welcome.lua", "init.lua", "uninstall.sh"):
        shutil.copy2(os.path.join(HERE, "payload", name), os.path.join(support, name))
        os.chmod(os.path.join(support, name), 0o755 if name.endswith(".sh") else 0o644)

    for dirpath, dirnames, _ in os.walk(root):
        for d in dirnames:
            p = os.path.join(dirpath, d)
            if not os.path.islink(p):
                os.chmod(p, 0o755)
    os.chmod(root, 0o755)

    kbytes = install_kbytes(root)
    nfiles = write_cpio_gz(root, os.path.join(pkgdir, "Payload"))
    print("Payload: %d Einträge, %d kB installiert" % (nfiles, kbytes))

    # ---- Scripts ----------------------------------------------------------
    for name in ("preinstall", "postinstall"):
        target = os.path.join(scripts, name)
        shutil.copy2(os.path.join(HERE, "scripts", name), target)
        os.chmod(target, 0o755)
    write_cpio_gz(scripts, os.path.join(pkgdir, "Scripts"))

    # ---- Bom --------------------------------------------------------------
    subprocess.run([MKBOM, "-u", "0", "-g", "0", root, os.path.join(pkgdir, "Bom")],
                   check=True)

    # ---- PackageInfo ------------------------------------------------------
    package_info = """<?xml version="1.0" encoding="utf-8"?>
<pkg-info format-version="2" identifier="{ident}" version="{ver}"
          install-location="/" relocatable="false" overwrite-permissions="true"
          followSymLinks="true" auth="root">
    <payload installKBytes="{kb}" numberOfFiles="{n}"/>
    <scripts>
        <preinstall file="preinstall"/>
        <postinstall file="postinstall"/>
    </scripts>
</pkg-info>
""".format(ident=IDENTIFIER, ver=VERSION, kb=kbytes, n=nfiles)
    with open(os.path.join(pkgdir, "PackageInfo"), "w") as fh:
        fh.write(package_info)

    # ---- Distribution -----------------------------------------------------
    distribution = """<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>Quitly</title>
    <organization>de.humandigitals</organization>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    <volume-check>
        <allowed-os-versions>
            <os-version min="11.0"/>
        </allowed-os-versions>
    </volume-check>
    <welcome file="welcome.html" mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <choices-outline>
        <line choice="default">
            <line choice="{ident}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="{ident}" visible="false">
        <pkg-ref id="{ident}"/>
    </choice>
    <pkg-ref id="{ident}" version="{ver}" onConclusion="none"
             installKBytes="{kb}" auth="Root">#{pkgdir}</pkg-ref>
</installer-gui-script>
""".format(ident=IDENTIFIER, ver=VERSION, kb=kbytes, pkgdir=PKG_DIR_NAME)
    with open(os.path.join(flat, "Distribution"), "w") as fh:
        fh.write(distribution)

    for name in ("welcome.html", "conclusion.html"):
        shutil.copy2(os.path.join(HERE, "resources", name), os.path.join(resources, name))

    # ---- xar --------------------------------------------------------------
    entries = [
        XarFile("Distribution", os.path.join(flat, "Distribution")),
        XarDir("Resources", [
            XarFile("welcome.html", os.path.join(resources, "welcome.html")),
            XarFile("conclusion.html", os.path.join(resources, "conclusion.html")),
        ]),
        XarDir(PKG_DIR_NAME, [
            XarFile("PackageInfo", os.path.join(pkgdir, "PackageInfo")),
            XarFile("Bom", os.path.join(pkgdir, "Bom")),
            XarFile("Payload", os.path.join(pkgdir, "Payload")),
            XarFile("Scripts", os.path.join(pkgdir, "Scripts")),
        ]),
    ]

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    build_xar(entries, OUT)
    print("Fertig: %s (%.1f MB)" % (OUT, os.path.getsize(OUT) / 1048576.0))


if __name__ == "__main__":
    sys.exit(main())
