#!/usr/bin/env python3
"""Make a FAT16 or FAT32 SD card image holding one file, for the sd_menu
benches.

The filesystem is made with mkfs.fat, either at block 0 (a superfloppy) or
in the first partition of an MBR. The file is then written to the root
directory in runs of clusters separated by free clusters, so that it has
several extents. The extent table, in the format sd_menu reads from its
buffer at launch, is written to a second file: 64 entries of 8 bytes, each
holding the first block (4 bytes, little endian), the number of blocks (2
bytes, little endian) and 2 bytes of zero. Extents cover whole clusters, so
the last one usually runs past the end of the file.

--root-fill puts empty files in the root directory before the file, so that
it spans several blocks, and on FAT32 several clusters, which are fragmented
like the file. --decoys also puts entries there that the boot stub must
skip: a deleted copy of the file, a directory and a long name entry with the
file's name.
"""

import argparse
import os
import struct
import subprocess
import sys
import tempfile

MKFS_FAT = "/usr/sbin/mkfs.fat"
BLOCK_BYTES = 512
EXTENTS = 64
ENTRY_BYTES = 32

PART_TYPES = {16: 0x0E, 32: 0x0C}


def name83(name):
    base, ext = os.path.splitext(name.upper())
    return (base[:8].ljust(8) + ext[1:4].ljust(3)).encode("ascii")


def entry(name, attr, cluster, size):
    return name + bytes([attr]) + bytes(8) + \
        struct.pack("<H", cluster >> 16) + bytes(4) + \
        struct.pack("<HI", cluster & 0xFFFF, size)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", help="image file to make")
    parser.add_argument("extents", help="extent table file to make")
    parser.add_argument("file", help="file to store in the image")
    parser.add_argument("--name",
                        help="name of the file on the card (default: the "
                             "file's own name)")
    parser.add_argument("--fat", type=int, choices=(16, 32), default=16,
                        help="FAT type (default 16)")
    parser.add_argument("--size-kb", type=int, default=4096,
                        help="size of the filesystem in KB (default 4096)")
    parser.add_argument("--cluster-blocks", type=int, default=1,
                        help="blocks per cluster (default 1)")
    parser.add_argument("--run", type=int, default=37,
                        help="clusters in each run of the file (default 37)")
    parser.add_argument("--gap", type=int, default=5,
                        help="free clusters between runs (default 5)")
    parser.add_argument("--skip", type=int, default=11,
                        help="free clusters before the file (default 11)")
    parser.add_argument("--mbr-start", type=int, default=0,
                        help="put the filesystem in the first partition of "
                             "an MBR, starting at this block (default 0: no "
                             "MBR)")
    parser.add_argument("--part-type", type=lambda s: int(s, 0),
                        help="MBR partition type (default 0x0E for FAT16, "
                             "0x0C for FAT32)")
    parser.add_argument("--gpt", action="store_true",
                        help="make the MBR a GPT protective MBR (type 0xEE)")
    parser.add_argument("--root-fill", type=int, default=0,
                        help="empty files before the file in the root "
                             "directory (default 0)")
    parser.add_argument("--decoys", action="store_true",
                        help="entries the boot stub must skip before the "
                             "file")
    args = parser.parse_args()

    with open(args.file, "rb") as f:
        data = f.read()

    with tempfile.TemporaryDirectory() as tmp:
        fs_path = os.path.join(tmp, "fs.img")
        subprocess.run([MKFS_FAT, "-C", "-F", str(args.fat), "-s",
                        str(args.cluster_blocks), "-h", str(args.mbr_start),
                        "-n", "SDMENU", fs_path, str(args.size_kb)],
                       check=True, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
        with open(fs_path, "rb") as f:
            fs = bytearray(f.read())

    boot = fs[:BLOCK_BYTES]
    (bytes_per_sector, sectors_per_cluster, reserved, num_fats,
     root_entries, _, _, fat_sectors) = struct.unpack_from("<HBHBHHBH",
                                                           boot, 11)
    assert bytes_per_sector == BLOCK_BYTES
    if args.fat == 32:
        fat_sectors, = struct.unpack_from("<I", boot, 0x24)
        root_cluster, = struct.unpack_from("<I", boot, 0x2C)
    eoc = 0x0FFFFFFF if args.fat == 32 else 0xFFFF
    entry_bytes = args.fat // 8

    root_block = reserved + num_fats * fat_sectors
    root_blocks = (root_entries * ENTRY_BYTES + BLOCK_BYTES - 1) // \
        BLOCK_BYTES
    data_block = root_block + root_blocks
    cluster_bytes = sectors_per_cluster * BLOCK_BYTES

    def cluster_block(c):
        return data_block + (c - 2) * sectors_per_cluster

    def set_fat(c, value):
        for n in range(num_fats):
            offset = (reserved + n * fat_sectors) * BLOCK_BYTES + \
                entry_bytes * c
            if args.fat == 32:
                struct.pack_into("<I", fs, offset, value)
            else:
                struct.pack_into("<H", fs, offset, value)

    def chain(clusters):
        for i, c in enumerate(clusters):
            set_fat(c, clusters[i + 1] if i + 1 < len(clusters) else eoc)

    next_cluster = 2 + args.skip
    if args.fat == 32:
        next_cluster += root_cluster - 1

    def allocate(count):
        nonlocal next_cluster
        clusters = []
        while len(clusters) < count:
            take = min(args.run, count - len(clusters))
            clusters.extend(range(next_cluster, next_cluster + take))
            next_cluster += take + args.gap
        return clusters

    # Root directory entries: the volume label that mkfs.fat wrote, the
    # fill, the decoys and the file
    name = name83(args.name or os.path.basename(args.file))
    entries = [entry(b"SDMENU     ", 0x08, 0, 0)]
    for i in range(args.root_fill):
        entries.append(entry(("FILL%04d" % i).encode("ascii") + b"BIN",
                             0x20, 0, 0))
    if args.decoys:
        entries.append(b"\xE5" + entry(name, 0x20, 0, 0)[1:])
        entries.append(entry(name, 0x10, 0, 0))
        entries.append(bytes([0x41]) + name[:10] + bytes([0x0F]) +
                       bytes(ENTRY_BYTES - 12))

    num_clusters = max(1, (len(data) + cluster_bytes - 1) // cluster_bytes)
    clusters = allocate(num_clusters)
    entries.append(entry(name, 0x20, clusters[0], len(data)))
    root = b"".join(entries)

    if args.fat == 32:
        per_cluster = cluster_bytes // ENTRY_BYTES
        need = (len(entries) + per_cluster - 1) // per_cluster
        root_clusters = [root_cluster] + allocate(need - 1)
        chain(root_clusters)
        for i, c in enumerate(root_clusters):
            chunk = root[i * cluster_bytes:(i + 1) * cluster_bytes]
            offset = cluster_block(c) * BLOCK_BYTES
            fs[offset:offset + len(chunk)] = chunk
    else:
        if len(entries) > root_entries:
            sys.exit("root directory is full")
        offset = root_block * BLOCK_BYTES
        fs[offset:offset + len(root)] = root

    chain(clusters)
    for i, c in enumerate(clusters):
        chunk = data[i * cluster_bytes:(i + 1) * cluster_bytes]
        offset = cluster_block(c) * BLOCK_BYTES
        if offset + len(chunk) > len(fs):
            sys.exit("the file does not fit")
        fs[offset:offset + len(chunk)] = chunk

    # Extents of contiguous clusters
    extents = []
    for c in clusters:
        block = args.mbr_start + cluster_block(c)
        if extents and extents[-1][0] + extents[-1][1] == block:
            extents[-1][1] += sectors_per_cluster
        else:
            extents.append([block, sectors_per_cluster])
    if len(extents) > EXTENTS:
        sys.exit("%d extents, more than %d" % (len(extents), EXTENTS))

    with open(args.image, "wb") as img:
        if args.mbr_start > 0:
            mbr = bytearray(args.mbr_start * BLOCK_BYTES)
            part_type = 0xEE if args.gpt else \
                (args.part_type if args.part_type is not None
                 else PART_TYPES[args.fat])
            # Status, CHS start (unused), type, CHS end, LBA start, blocks
            struct.pack_into("<B3sB3sII", mbr, 0x1BE, 0, b"\xFE\xFF\xFF",
                             part_type, b"\xFE\xFF\xFF", args.mbr_start,
                             len(fs) // BLOCK_BYTES)
            mbr[0x1FE:0x200] = b"\x55\xAA"
            img.write(mbr)
        elif args.gpt:
            sys.exit("--gpt needs --mbr-start")
        img.write(fs)

    table = b"".join(struct.pack("<IHH", b, n, 0) for b, n in extents)
    with open(args.extents, "wb") as f:
        f.write(table.ljust(EXTENTS * 8, b"\0"))

    for b, n in extents:
        print("extent: block %d, %d blocks" % (b, n))


if __name__ == "__main__":
    main()
