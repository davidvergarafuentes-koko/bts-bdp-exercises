# Exercise 1: Your First GitHub Actions Workflow

## Objective
Understand how a GitHub Actions workflow runs automatically when you push code to your repository.

## Steps Performed

### 1. Fork and clone the repository
```bash
git clone https://github.com/YOUR_USER/bts-bdp-exercises.git
cd bts-bdp-exercises
```

### 2. Enable GitHub Actions on the fork
- Go to the fork on GitHub → **Actions** tab → Click **"I understand my workflows, go ahead and enable them"**

### 3. Project structure
```
bts-bdp-exercises/
  .github/workflows/
    ci.yml               # Active workflow
  solutions/             # Reference solutions for each exercise
  app/
    main.py              # FastAPI application
    test_main.py         # Tests
    requirements.txt     # Dependencies
    Dockerfile           # Container definition
```

### 4. Active workflow reviewed (`ci.yml`)
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Say hello
        run: echo "Hello CI! My first GitHub Actions workflow."
      - name: Check Python version
        run: python --version
```

### 5. Trigger the workflow
```bash
echo "# My fork" >> README.md
git add README.md
git commit -m "feat: trigger first workflow"
git push origin main
```

### 6. Result
- Green checkmark on the Actions tab
- Logs show: `Hello CI! My first GitHub Actions workflow.`
- Python version displayed in the runner

## Key Concepts

| Concept | Description |
|---------|-------------|
| `on` | Defines **when** the workflow triggers (push, pull_request) |
| `jobs` | Contains the **work** to be done |
| `steps` | **Sequential tasks** within a job |
| `uses` | References a **reusable action** from the marketplace (e.g., `actions/checkout@v4`) |
| `run` | Executes a **shell command** |
| Workflow location | Workflows must live in `.github/workflows/*.yml` |

## Questions & Answers

**Q: Where do GitHub Actions workflows live?**
A: In the `.github/workflows/` directory of the repository, as YAML files.

**Q: What triggers this workflow?**
A: Any `push` to `main` or any `pull_request` targeting `main`.

**Q: What does `actions/checkout@v4` do?**
A: It clones the repository code into the runner so subsequent steps can access it.

**Q: What does `runs-on: ubuntu-latest` mean?**
A: The job runs on a GitHub-hosted runner with the latest Ubuntu version.
