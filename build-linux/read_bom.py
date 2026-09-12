#!/usr/bin/env python3
"""Minimaler BOM-Leser. Ersatz für lsbom, das in diesem Build segfaultet."""

import struct
import sys


class Bom:
    def __init__(self, data):
        self.d = data
        magic, version, nblocks, index_off, index_len, vars_off, vars_len = \
            struct.unpack_from(">8sIIIIII", data, 0)
        assert magic == b"BOMStore", magic
        self.version = version
        n = struct.unpack_from(">I", data, index_off)[0]
        self.blocks = []
        for i in range(n):
            addr, length = struct.unpack_from(">II", data, index_off + 4 + i * 8)
            self.blocks.append((addr, length))
        self.vars = {}
        count = struct.unpack_from(">I", data, vars_off)[0]
        p = vars_off + 4
        for _ in range(count):
            idx, ln = struct.unpack_from(">IB", data, p)
            p += 5
            name = data[p:p + ln].decode("ascii")
            p += ln
            self.vars[name] = idx

    def block(self, bid):
        addr, length = self.blocks[bid]
        return self.d[addr:addr + length]

    def paths(self):
        tree = self.block(self.vars["Paths"])
        _magic, _ver, child, _bs, _pc, _u = struct.unpack_from(">4sIIIIB", tree, 0)
        out = []
        self._walk(child, out)
        return out

    def _walk(self, bid, out):
        node = self.block(bid)
        is_leaf, count, forward, backward = struct.unpack_from(">HHII", node, 0)
        for i in range(count):
            i0, i1 = struct.unpack_from(">II", node, 12 + i * 8)
            if is_leaf:
                out.append(self._entry(i0, i1))
            else:
                self._walk(i0, out)
        if is_leaf and forward:
            self._walk(forward, out)

    def _entry(self, info1_id, file_id):
        b = self.block(file_id)
        parent = struct.unpack_from(">I", b, 0)[0]
        name = b[4:].split(b"\0")[0].decode("utf-8", "surrogateescape")

        i1 = self.block(info1_id)
        pid, info2_id = struct.unpack_from(">II", i1, 0)

        i2 = self.block(info2_id)
        (ftype, _u0, _arch, mode, uid, gid, mtime, size, _u1) = \
            struct.unpack_from(">BBHHIIIIB", i2, 0)
        checksum, link_len = struct.unpack_from(">II", i2, 23)
        link = ""
        if link_len:
            link = i2[31:31 + link_len].split(b"\0")[0].decode("utf-8", "surrogateescape")
        return dict(id=pid, parent=parent, name=name, type=ftype, mode=mode,
                    uid=uid, gid=gid, mtime=mtime, size=size,
                    checksum=checksum, link=link)


def full_paths(entries):
    by_id = {e["id"]: e for e in entries}
    result = {}
    for e in entries:
        parts = [e["name"]]
        p = e["parent"]
        guard = 0
        while p and p in by_id and guard < 64:
            parts.append(by_id[p]["name"])
            p = by_id[p]["parent"]
            guard += 1
        result["/".join(reversed(parts))] = e
    return result


if __name__ == "__main__":
    bom = Bom(open(sys.argv[1], "rb").read())
    entries = bom.paths()
    paths = full_paths(entries)
    TYPE = {1: "file", 2: "dir", 3: "link", 4: "dev"}
    for p in sorted(paths):
        e = paths[p]
        extra = " -> " + e["link"] if e["link"] else ""
        print("%s\t%o\t%d/%d\t%s\t%d%s" %
              (p, e["mode"], e["uid"], e["gid"], TYPE.get(e["type"], "?"), e["size"], extra))
