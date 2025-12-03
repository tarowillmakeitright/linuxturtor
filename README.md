# linuxtutor 🐧

<p align="center">
  <img src="screenshot-20251203-201044.png" alt="linuxtutor thumbnail" width="700">
</p>

> A terminal-based Linux & DevOps quiz game, inspired by `vimtutor`  
> Learn real commands, concepts, and hardcore DevOps by *typing*, not scrolling blog posts.

`linuxtutor` runs in your terminal and quizzes you on:

- Linux commands (beginner → advanced)
- Filesystem layout, permissions, processes, networking concepts
- Real-world sysadmin tasks
- Git, Docker, Kubernetes, Terraform, Ansible
- **Hardcore DevOps exam mode** 💀

You answer by typing the exact command/keyword.  
Muscle memory + repetition = you don’t forget.

---

## ✨ Features

- 📁 **Question bank in a simple text file** (`questions.txt`)
- 🎚 **Categories**: choose what to practice (`BEGINNER`, `SYSADMIN`, `DOCKER`, `KUBERNETES`, etc.)
- 💀 **Hardcore DevOps Exam Mode**: only `DEVOPS-HARDCORE` questions
- 🎲 **Randomized questions** each time (Fisher–Yates shuffle)
- ❓ `?` or `skip` → **show the answer and move on**
- 🚪 `end` → **quit the current lesson and go back to category menu**
- ❤️ 3 attempts per question → then show the answer
- 🔁 Loop back and choose another lesson without restarting the script
- 🧠 All plain Bash — runs on basically any Linux distro

No database, no server, no browser.  
Just you, your terminal, and your shame when you forget `chmod 755` again.

---

## 🧩 How it works

There are two main pieces:

1. **`linuxtutor`** – the Bash script
2. **`questions.txt`** – the question bank

The script:

- Loads all lines from `questions.txt`
- Builds a list of categories from the first `|`-separated field
- Lets you pick:
  - a **specific category**
  - **HARDCORE DEVOPS MODE 💀**
  - or **ALL (mixed)**
- Shuffles questions
- Asks them one by one

---

## 📦 Installation

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/linuxtutor.git
cd linuxtutor
````

### 2. Make the script executable

```bash
chmod +x linuxtutor
```

### 3. (Optional) Install globally

**User-local install:**

```bash
mkdir -p "$HOME/bin"
cp linuxtutor "$HOME/bin/"
# Add this to ~/.bashrc or ~/.zshrc if not already
export PATH="$HOME/bin:$PATH"
```

Then you can run:

```bash
linuxtutor
```

**System-wide (requires sudo):**

```bash
sudo cp linuxtutor /usr/local/bin/
```

Now every user can run:

```bash
linuxtutor
```

---

## 🧾 `questions.txt` format

All questions come from `questions.txt`.
Each **non-comment** line is:

```text
CATEGORY|QUESTION|ANSWER
```

* `CATEGORY` → e.g. `BEGINNER`, `SYSADMIN`, `DOCKER`, `DEVOPS-HARDCORE`
* `QUESTION` → the prompt shown to the user
* `ANSWER` → the exact string the user must type to count as correct

Lines starting with `#` or empty lines are ignored.

### Example entries

```text
# ===== Beginner =====
BEGINNER|List files in current directory|ls
BEGINNER|Show current working directory|pwd

# ===== Sysadmin =====
SYSADMIN|Check system uptime|uptime
SYSADMIN|Restart httpd|sudo systemctl restart httpd

# ===== DevOps: Docker =====
DOCKER|List running containers|docker ps
DOCKER|Build an image myapp:latest from current dir|docker build -t myapp:latest .

# ===== Hardcore DevOps =====
DEVOPS-HARDCORE|What does SLO stand for?|service level objective
DEVOPS-HARDCORE|What happens when a pod exceeds its memory limit?|OOMKilled
```

You can organize questions with comment headers like:

```text
# ===== Real-World Sysadmin Tasks =====
# ===== DevOps Pack: Docker =====
# ===== DevOps Pack: Kubernetes =====
```

They’re just for humans — the script ignores them.

---

## 🕹 Usage

From the project directory:

```bash
./linuxtutor
```

### 1. Choose a category

The script scans `questions.txt` and shows something like:

```text
=======================================
            Linux Tutor
=======================================
Questions file: questions.txt

Choose a category:
   1) BEGINNER
   2) INTERMEDIATE
   3) ADVANCED
   4) SYSADMIN
   5) FS
   6) PERMISSIONS
   7) SHELL
   8) PROCESS
   9) SYSTEMD
  10) NETWORK
  11) SECURITY
  12) TRIVIA
  13) DOCKER
  14) KUBERNETES
  15) GIT
  16) DEVOPS-HARDCORE
  17) HARDCORE DEVOPS MODE 💀
  18) ALL (mixed)

Enter number:
```

* Pick a **specific category** (e.g. `BEGINNER`)
* Or pick **HARDCORE DEVOPS MODE 💀** → this uses **only** `DEVOPS-HARDCORE` questions
  (even if you have many other categories)
* Or pick **ALL (mixed)** → random questions from every category

### 2. Answer questions

For each question, you’ll see something like:

```text
[3/25] Restart httpd
> 
```

You type the exact answer from `questions.txt`, e.g.:

```text
> sudo systemctl restart httpd
✅ Correct!
```

### 3. Controls during a lesson

Inside a quiz, you can:

* `?` or `skip` → **skip & immediately show correct answer**

  ```text
  > ?
  ⏭ Skipped.
     Correct answer: sudo systemctl restart httpd
  ```

* `end` → **stop the current lesson and go back to the category menu**

  ```text
  > end
  🚪 Ending this lesson and returning to the main menu...
  ```

* If you answer **wrong 3 times**, it reveals the answer and moves on:

  ```text
  > sudo restart httpd
  ❌ Not quite. Try again. (Attempt 1/3)
  ...
  ❌ Wrong 3 times.
     Correct answer: sudo systemctl restart httpd
  ```

At the end of a lesson, you get a summary:

```text
=======================================
  Finished!
  Score: 19 / 25
  Accuracy: 76 %
=======================================

Play another lesson? (y/n):
```

Press `y` → pick another category;
Press anything else → exit.

---

## 💀 Hardcore DevOps Mode

This special mode exists purely to hurt you in the best possible way.

When you select:

```text
HARDCORE DEVOPS MODE 💀
```

The script will:

* Load **only** questions with category `DEVOPS-HARDCORE`
* Shuffle them
* Throw them at your brain

Examples of hardcore questions:

* `What happens when a pod exceeds its memory limit?` → `OOMKilled`
* `Which kubelet flag controls eviction thresholds?` → `--eviction-hard`
* `Which file stores Terraform state by default?` → `terraform.tfstate`
* `Default GitHub Actions workflow directory?` → `.github/workflows`
* `What does SLO stand for?` → `service level objective`

You can grow this pack over time into your own private SRE/DevOps exam.

---

## 🧠 Adding your own questions

1. Open `questions.txt`
2. Pick or create a category name (no spaces recommended, but allowed if you know what you’re doing)
3. Add lines like:

```text
MYFAVCMD|List all files recursively with details|ls -lR
K8S-EXAM|Show pods in all namespaces|kubectl get pods -A
```

4. Save the file and run `linuxtutor` again —
   your new categories will appear automatically if they’re new.

### Category naming ideas

* `BASH`
* `SED-AWK`
* `REGEX`
* `OCI`
* `GCP`
* `AWS`
* `K8S-NETWORKING`
* `LINUX-INTERVIEW`

You can be as serious or as cursed as you want.

---

## 🧪 Development

Run locally:

```bash
./linuxtutor
```

If you want to test with another question file:

```bash
QUESTIONS_FILE=demo_questions.txt ./linuxtutor
```

Nice for working on small packs without touching your main `questions.txt`.

---

## 🤝 Contributing

Contributions very welcome:

* New **question packs** (`questions.txt` additions)
* Better categorization
* Colors / TUI improvements
* Packaging (RPM / DEB / AUR / Homebrew)

### Basic flow

1. Fork the repo

2. Create a branch:

   ```bash
   git checkout -b feature/new-question-pack
   ```

3. Edit `questions.txt` or `linuxtutor`

4. Commit + push:

   ```bash
   git commit -am "Add advanced Kubernetes networking questions"
   git push origin feature/new-question-pack
   ```

5. Open a Pull Request

Try to keep new questions in the same `CATEGORY|QUESTION|ANSWER` format, and be consistent with wording.

---

## 📜 License

MIT.
Do whatever you want — use it, fork it, ship it with your own distro, teach juniors, torture seniors.

---

## 🧘 Motto

> Stay humble. Stay hungry.
> Ship scripts. Forget less. Learn more.

If you break your brain on **Hardcore DevOps mode**, that’s working as intended.
If you want help defining more question packs (OCI, GCP, SRE, Linux interview, etc.), you can absolutely keep extending it.
This can become your personal “command gym”.

Happy hacking 🐧



