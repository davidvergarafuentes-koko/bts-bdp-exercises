# Exercise 4: Complete CI/CD Pipeline with Pull Requests

## Objective
Experience the complete professional CI/CD workflow: branch protection, feature branches, pull requests, and automated checks.

## Steps Performed

### 1. Replace the workflow
```bash
cp solutions/exercise4_cicd.yml .github/workflows/ci.yml
```

### 2. New workflow reviewed — Three-stage pipeline
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      # ... lint + test

  docker:
    needs: ci
    runs-on: ubuntu-latest
    steps:
      # ... build Docker image

  deploy:
    needs: docker
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        run: echo "Deploying bts-bdp-app:latest to production..."
      - name: Verify deployment
        run: echo "Deployment complete. Application is live."
```

```bash
git add .github/workflows/ci.yml
git commit -m "feat: activate full CI/CD pipeline"
git push origin main
```

### 3. Enable branch protection (manual step)

> **Manual steps on GitHub:**
> 1. Go to **Settings > Branches**
> 2. Click **Add branch protection rule**
> 3. Branch name pattern: `main`
> 4. Enable:
>    - Require a pull request before merging
>    - Require status checks to pass before merging
>    - Select the CI workflow as a required check
> 5. Click **Create**

### 4. Create a feature branch
```bash
git checkout -b feat/add-info-endpoint
```

### 5. Add the `/info` endpoint to `app/main.py`
```python
@app.get("/info")
def info():
    return {"session": "S9", "topic": "DevOps & CI/CD"}
```

### 6. Push the feature branch
```bash
git add app/main.py
git commit -m "feat: add info endpoint"
git push origin feat/add-info-endpoint
```

### 7. Open a Pull Request (manual step)

> **On GitHub:**
> 1. Click **Compare & pull request**
> 2. Add a title and description
> 3. Click **Create pull request**

### 8. Observe CI on the PR
- Status checks run directly on the PR page
- Merge button is **blocked** until all checks pass
- Only `ci` and `docker` run — `deploy` is **skipped** (it's a PR, not a push to main)

### 9. Merge when green
- Click **Merge pull request** → Delete the feature branch
- The merge triggers a new run where `deploy` **now executes**

## Pipeline Visualization

```
On Pull Request:
┌──────────┐      ┌──────────┐      ┌──────────┐
│    ci     │─────▶│  docker   │      │  deploy   │
│ lint+test │      │   build   │      │ (skipped) │
└──────────┘      └──────────┘      └──────────┘

On Push to main (after merge):
┌──────────┐      ┌──────────┐      ┌──────────┐
│    ci     │─────▶│  docker   │─────▶│  deploy   │
│ lint+test │      │   build   │      │ production│
└──────────┘      └──────────┘      └──────────┘
```

## Key Concepts

| Concept | Description |
|---------|-------------|
| Branch protection | Enforces **quality gates** — no direct pushes to main |
| Feature branches | Isolate changes until validated |
| Pull requests | Enable **code review** and discussion |
| `if: github.event_name == 'push'` | Controls which jobs run on PRs vs merges |
| Three-stage pipeline | CI → Build → Deploy |
| `needs: docker` | Deploy depends on a successful Docker build |

## Questions & Answers

**Q: Why does the `deploy` job have an `if` condition?**
A: To ensure deployment only happens on pushes to `main` (after merge), not on pull requests. You don't want to deploy unreviewed code.

**Q: What is branch protection?**
A: A GitHub setting that prevents direct pushes to a branch and requires PRs with passing status checks before merging.

**Q: Why use feature branches instead of pushing directly to main?**
A: Feature branches isolate changes, enable code review via PRs, and allow CI to validate changes before they reach main.

**Q: What happens if CI fails on a PR?**
A: The merge button is blocked. You must fix the issue and push again before merging.

**Q: How does this scale for teams?**
A: This same workflow works for teams of any size. Everyone creates feature branches, opens PRs, and CI validates automatically.

**Q: What would a real deploy step look like?**
A: Instead of `echo`, it would push the Docker image to a registry and deploy to a cloud provider (AWS ECS, Kubernetes, etc.).
