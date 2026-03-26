# Exercise 2: Adding Linting and Tests to CI

## Objective
See how a CI workflow runs code quality checks (linting) and automated tests, and what happens when code quality fails.

## Steps Performed

### 1. Replace the workflow
```bash
cp solutions/exercise2_lint_test.yml .github/workflows/ci.yml
```

### 2. New workflow reviewed
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r app/requirements.txt

      - name: Lint with ruff
        run: ruff check app/

      - name: Run tests
        run: pytest app/ -v
```

### 3. Push and see it pass
```bash
git add .github/workflows/ci.yml
git commit -m "feat: add lint and test steps to CI"
git push origin main
```

### 4. Break it on purpose
Add an unused import to `app/main.py`:
```python
import os  # This import is unused
```

```bash
git add app/main.py
git commit -m "test: introduce lint error"
git push origin main
```

### 5. Observe the failure
- Red X on Actions tab
- The **"Lint with ruff"** step shows the error: unused import `os`
- Tests **did not run** because lint failed first (steps are sequential)

### 6. Fix it
Remove the unused import, push again:
```bash
git add app/main.py
git commit -m "fix: remove unused import"
git push origin main
```

## Differences from Exercise 1

| Feature | Exercise 1 | Exercise 2 |
|---------|-----------|-----------|
| Python setup | System default | `actions/setup-python@v5` with Python 3.11 |
| Dependencies | None | `pip install -r app/requirements.txt` |
| Linting | None | `ruff check app/` |
| Tests | None | `pytest app/ -v` |

## Key Concepts

| Concept | Description |
|---------|-------------|
| `actions/setup-python@v5` | Installs a **specific Python version** on the runner |
| `ruff check` | Static code analysis - catches unused imports, style issues, etc. |
| `pytest` | Runs automated tests |
| Sequential steps | If lint fails, tests **don't run** — fail fast |
| Fast feedback | You know within minutes if your code is correct |

## Questions & Answers

**Q: Why do we set up a specific Python version instead of using the default?**
A: To ensure consistent behavior across all runs. The default Python on `ubuntu-latest` can change over time.

**Q: What happens if linting fails?**
A: The workflow stops at the lint step. Tests don't run. The run shows a red X.

**Q: What is `ruff`?**
A: A fast Python linter that catches code quality issues like unused imports, style violations, and potential bugs.

**Q: Why is sequential step ordering important in CI?**
A: It provides a fail-fast approach — no point running tests if the code doesn't even pass basic quality checks.
