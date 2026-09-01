# Soft Link vs. Hard Link

## 1. Inodes in Linux

Files in Linux are tracked by **inodes** (Index Nodes).
- **Inode:** Stores metadata (permissions, owner UID, size, timestamps) and disk block pointers. Does not store the filename.
- **Directory Entry:** Maps a filename string to an inode number.

<img src="https://github.com/user-attachments/assets/34ce3d1b-b5e4-4460-8786-fddd0bdb7d76" alt="Inode Architecture Diagram" width="100%" />

---

## 2. Core Differences

<img src="https://github.com/user-attachments/assets/d83f9c34-e485-420a-a8a3-ccc14bc59a73" alt="Hard Link vs Soft Link Architecture Diagram" width="600" />

- **Hard Link (`ln file link`):** Points to the existing inode. Increments link count. File data remains accessible even if the original name is deleted. Cannot cross filesystems or link directories.
- **Soft Link (`ln -s target link`):** A separate file containing the target path string. Has its own inode. Breaks if target is moved or deleted. Can cross filesystems and link directories.

---

## 3. Comparison Table

| Feature | Hard Link | Soft Link |
| :--- | :--- | :--- |
| Inode Number | Same as target | Unique separate inode |
| Link Count | Increases target's link count | Does not change target's link count |
| Cross-Filesystem | No | Yes |
| Directory Support | No | Yes |
| Target Deletion | Data remains intact | Link breaks (dangling) |
| Command | `ln file.txt hard.txt` | `ln -s file.txt soft.txt` |

---

## 4. Commands and Verification

### Create links:
```bash
ln original.txt hardlink.txt
ln -s original.txt softlink.txt
```

### Inspect inodes:
```bash
ls -li
```
```text
1054238 -rw-r--r-- 2 user user 20 Sep 2 12:00 hardlink.txt
1054238 -rw-r--r-- 2 user user 20 Sep 2 12:00 original.txt
1054245 lrwxrwxrwx 1 user user 12 Sep 2 12:01 softlink.txt -> original.txt
```

### Deletion behavior:
```bash
rm original.txt

cat hardlink.txt  # Works (data still exists on inode)
cat softlink.txt  # Error: No such file or directory
```

### Remove links:
```bash
rm softlink.txt
rm hardlink.txt
```

---

## 5. Interview Questions

**Q1: What happens when the original file is deleted?**
- Hard link keeps the file data accessible until all links are removed (link count = 0).
- Soft link becomes broken because it only stored the deleted file's path.

**Q2: Why can't hard links span across filesystems?**
- Inode numbers are only unique per filesystem partition. Inode 100 on disk A has no relation to Inode 100 on disk B. Soft links work because they reference path strings instead of inode numbers.

**Q3: Why are directory hard links not allowed?**
- To prevent loops/cycles in the filesystem tree, which would break directory traversals (`find`, `du`, `rm -rf`).

**Q4: How do you find broken soft links?**
```bash
find . -xtype l
find . -xtype l -delete
```
