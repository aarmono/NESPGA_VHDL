#!/usr/bin/env python3
"""Make a FAT16 SD card image holding one file, for the sd_menu bench.

The filesystem is made with mkfs.fat, without a partition table (a
superfloppy). The file is then written in runs of clusters separated by free
clusters, so that it has several extents. The extent table, in the format
sd_menu reads from its buffer at launch, is written to a second file: 64
entries of 8 bytes, each holding the first block (4 bytes, little endian),
the number of blocks (2 bytes, little endian) and 2 bytes of zero. Extents
cover whole clusters, so the last one usually runs past the end of the file.
"""

import argparse
import os
import struct
import subprocess
import sys

MKFS_FAT = "/usr/sbin/mkfs.fat"
BLOCK_BYTES = 512
EXTENTS = 64


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", help="image file to make")
    parser.add_argument("extents", help="extent table file to make")
    parser.add_argument("file", help="file to store in the image")
    parser.add_argument("--size-kb", type=int, default=4096,
                        help="size of the image in KB (default 4096)")
    parser.add_argument("--cluster-blocks", type=int, default=1,
                        help="blocks per cluster (default 1)")
    parser.add_argument("--run", type=int, default=37,
                        help="clusters in each run of the file (default 37)")
    parser.add_argument("--gap", type=int, default=5,
                        help="free clusters between runs (default 5)")
    parser.add_argument("--skip", type=int, default=11,
                        help="free clusters before the file (default 11)")
    args = parser.parse_args()

    with open(args.file, "rb") as f:
        data = f.read()

    if os.path.exists(args.image):
        os.remove(args.image)
    subprocess.run([MKFS_FAT, "-C", "-F", "16", "-s",
                    str(args.cluster_blocks), "-n", "SDMENU", args.image,
                    str(args.size_kb)],
                   check=True, stdout=subprocess.DEVNULL)

    with open(args.image, "r+b") as img:
        boot = img.read(BLOCK_BYTES)
        (bytes_per_sector, sectors_per_cluster, reserved, num_fats,
         root_entries, _, _, fat_sectors) = struct.unpack_from(
             "<HBHBHHBH", boot, 11)
        assert bytes_per_sector == BLOCK_BYTES

        root_block = reserved + num_fats * fat_sectors
        root_blocks = (root_entries * 32 + BLOCK_BYTES - 1) // BLOCK_BYTES
        data_block = root_block + root_blocks
        cluster_bytes = sectors_per_cluster * BLOCK_BYTES

        # Clusters of the file, in runs separated by gaps
        num_clusters = max(1, (len(data) + cluster_bytes - 1) // cluster_bytes)
        clusters = []
        cluster = 2 + args.skip
        while len(clusters) < num_clusters:
            take = min(args.run, num_clusters - len(clusters))
            clusters.extend(range(cluster, cluster + take))
            cluster += take + args.gap

        # FAT chain, in every copy of the FAT
        fat_start = reserved * BLOCK_BYTES
        for i, c in enumerate(clusters):
            nxt = clusters[i + 1] if i + 1 < len(clusters) else 0xFFFF
            for n in range(num_fats):
                img.seek(fat_start + n * fat_sectors * BLOCK_BYTES + 2 * c)
                img.write(struct.pack("<H", nxt))

        # Directory entry, after the volume label
        name, ext = os.path.splitext(os.path.basename(args.file).upper())
        name83 = (name[:8].ljust(8) + ext[1:4].ljust(3)).encode("ascii")
        entry = name83 + bytes([0x20]) + bytes(14) + \
            struct.pack("<HI", clusters[0], len(data))
        img.seek(root_block * BLOCK_BYTES)
        root = img.read(root_blocks * BLOCK_BYTES)
        for i in range(root_entries):
            if root[i * 32] == 0:
                img.seek(root_block * BLOCK_BYTES + i * 32)
                img.write(entry)
                break
        else:
            sys.exit("root directory is full")

        # File data
        for i, c in enumerate(clusters):
            chunk = data[i * cluster_bytes:(i + 1) * cluster_bytes]
            img.seek((data_block + (c - 2) * sectors_per_cluster) *
                     BLOCK_BYTES)
            img.write(chunk)

    # Extents of contiguous clusters
    extents = []
    for c in clusters:
        block = data_block + (c - 2) * sectors_per_cluster
        if extents and extents[-1][0] + extents[-1][1] == block:
            extents[-1][1] += sectors_per_cluster
        else:
            extents.append([block, sectors_per_cluster])
    if len(extents) > EXTENTS:
        sys.exit("%d extents, more than %d" % (len(extents), EXTENTS))

    table = b"".join(struct.pack("<IHH", b, n, 0) for b, n in extents)
    with open(args.extents, "wb") as f:
        f.write(table.ljust(EXTENTS * 8, b"\0"))

    for b, n in extents:
        print("extent: block %d, %d blocks" % (b, n))


if __name__ == "__main__":
    main()
