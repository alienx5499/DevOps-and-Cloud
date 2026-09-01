# Git & GitHub: Commit Automation and Cherry-Picking

A guide covering automatic staging with `git commit -a -m` and selective commit merging using `git cherry-pick`.

---

## 1. Task 1: `git commit -a -m` vs `git commit -m`

### 1.1 Key Differences

| Feature | `git commit -m "msg"` | `git commit -a -m "msg"` |
| :--- | :--- | :--- |
| **Staging requirement** | Requires running `git add` manually first | Automatically stages tracked modified/deleted files |
| **Untracked (new) files** | Ignores unless explicitly added with `git add` | **Does NOT stage untracked files** (still requires `git add`) |
| **Deleted tracked files** | Stages only if `git rm` or `git add` was run | Automatically stages deletions of tracked files |
| **Common use case** | Atomic commits where only specific files should land | Quick edits across already tracked project files |

---

### 1.2 Practical Demonstration

```bash
# 1. Modify an existing tracked file
echo "Updated database host" >> config.txt

# 2. Create a new untracked file
echo "Temporary notes" > notes.txt

# 3. Test git commit -a -m
git commit -a -m "feat: update config automatically"
git status
```

### Observation:
- `config.txt` is automatically staged and committed.
- `notes.txt` remains in the **Untracked files** section because `-a` only operates on files already tracked in the index.

<img src="https://github.com/user-attachments/assets/4b580a1c-b26b-479f-871a-f70b25fc6469" alt="git commit -a -m demonstration" width="100%" />

---

## 2. Task 2: Git Cherry-Pick

`git cherry-pick <commit-hash>` applies the exact changes introduced by an existing commit from another branch onto your current branch, generating a new commit with a new SHA hash.

### Cherry-Pick Architecture & Flow

<img src="https://github.com/user-attachments/assets/176556e3-e37d-4a85-8be4-85941dc6937e" alt="Cherry-Pick Architecture & Flow" width="600" />

---

### 2.1 Step-by-Step Execution

#### Step 1: Create commits on the `main` branch
```bash
echo "Main feature 1" >> config.txt && git commit -a -m "feat: add main feature 1"
echo "Main feature 2" >> config.txt && git commit -a -m "feat: add main feature 2"
```

#### Step 2: Create and switch to a new feature branch
```bash
git checkout -b feature-payments
```

#### Step 3: Make commits on the new branch
```bash
echo "Stripe payment logic" > payment.txt && git add payment.txt && git commit -m "feat: implement stripe"
echo "Hotfix discount calculation" > fix.txt && git add fix.txt && git commit -m "fix: resolve discount calculation bug"
echo "PayPal payment logic" >> payment.txt && git commit -a -m "feat: implement paypal"
```

#### Step 4: Identify the specific commit hash on the feature branch
```bash
git log --oneline -n 5
```

**Output:**
```text
3dbd32a (HEAD -> feature-payments) feat: implement paypal
9016da1 fix: resolve discount calculation bug
7489806 feat: implement stripe
66aa9f4 (main) feat: add main feature 2
f18f86d feat: add main feature 1
```

<img src="https://github.com/user-attachments/assets/9a1cd8a9-c7a9-40a9-b3dd-a6a129862c13" alt="Feature branch commit history" width="100%" />

#### Step 5: Switch back to `main` and cherry-pick the fix commit
```bash
git checkout main
git cherry-pick $(git log feature-payments --grep="fix: resolve" --format="%h")
```

**Output:**
```text
[main 0e7263e] fix: resolve discount calculation bug
 Date: Thu Sep 3 00:53:24 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 fix.txt
```

#### Step 6: Verify the cherry-picked commit on `main`
```bash
git log --oneline -n 5
```

**Output:**
```text
0e7263e (HEAD -> main) fix: resolve discount calculation bug
66aa9f4 feat: add main feature 2
f18f86d feat: add main feature 1
dbd7641 feat: update config automatically
6626ee2 feat: add initial config
```

<img src="https://github.com/user-attachments/assets/041561af-5978-4d7c-a37f-35dcd9388c9c" alt="Cherry-pick verification on main" width="100%" />

---

## 3. Summary of Key Learnings

1. **`git commit -a -m`**: Saves time on tracked files by automatically staging changes to files already indexed, but never adds untracked files.
2. **`git cherry-pick`**: Selectively pulls a specific bug fix or feature commit from an unmerged branch into `main` without merging unfinished code.
