# Homework: CI/CD for the Assignment Project

## Objective
Apply everything from the exercises by creating a CI/CD pipeline from scratch for `bts-bdp-assignment` and implement the S9 endpoints.

---

## Part 1: CI/CD Pipeline

### Workflow file: `.github/workflows/ci.yml`

Create this file in the `bts-bdp-assignment` repository:

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
        run: pip install -r requirements.txt

      - name: Lint with ruff
        run: ruff check .

      - name: Run tests
        run: pytest tests/ -v

  docker:
    needs: ci
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: docker/Dockerfile
          push: false
          tags: bts-bdp-assignment:latest
```

### Branch protection (manual step)

> **On GitHub → Settings → Branches → Add rule:**
> 1. Branch name pattern: `main`
> 2. Enable: **Require a pull request before merging**
> 3. Enable: **Require status checks to pass before merging**
> 4. Select the `ci` job as a required check
> 5. Click **Create**

---

## Part 2: S9 Endpoints

### Implementation: `bdi_api/s9/exercise.py`

```python
from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/api/s9", tags=["S9"])

PIPELINES = [
    {
        "id": "run-001",
        "repository": "bts-bdp-assignment",
        "branch": "main",
        "status": "success",
        "triggered_by": "push",
        "started_at": "2026-03-10T10:00:00Z",
        "finished_at": "2026-03-10T10:05:30Z",
        "stages": ["lint", "test", "build"],
    },
    {
        "id": "run-002",
        "repository": "bts-bdp-assignment",
        "branch": "feat/add-endpoint",
        "status": "failure",
        "triggered_by": "pull_request",
        "started_at": "2026-03-11T14:00:00Z",
        "finished_at": "2026-03-11T14:03:00Z",
        "stages": ["lint", "test"],
    },
]

STAGES = {
    "run-001": [
        {
            "name": "lint",
            "status": "success",
            "started_at": "2026-03-10T10:00:00Z",
            "finished_at": "2026-03-10T10:00:45Z",
            "logs_url": "/api/s9/pipelines/run-001/stages/lint/logs",
        },
        {
            "name": "test",
            "status": "success",
            "started_at": "2026-03-10T10:00:45Z",
            "finished_at": "2026-03-10T10:03:20Z",
            "logs_url": "/api/s9/pipelines/run-001/stages/test/logs",
        },
        {
            "name": "build",
            "status": "success",
            "started_at": "2026-03-10T10:03:20Z",
            "finished_at": "2026-03-10T10:05:30Z",
            "logs_url": "/api/s9/pipelines/run-001/stages/build/logs",
        },
    ],
    "run-002": [
        {
            "name": "lint",
            "status": "success",
            "started_at": "2026-03-11T14:00:00Z",
            "finished_at": "2026-03-11T14:00:30Z",
            "logs_url": "/api/s9/pipelines/run-002/stages/lint/logs",
        },
        {
            "name": "test",
            "status": "failure",
            "started_at": "2026-03-11T14:00:30Z",
            "finished_at": "2026-03-11T14:03:00Z",
            "logs_url": "/api/s9/pipelines/run-002/stages/test/logs",
        },
    ],
}


@router.get("/pipelines")
def list_pipelines():
    return PIPELINES


@router.get("/pipelines/{pipeline_id}/stages")
def get_pipeline_stages(pipeline_id: str):
    if pipeline_id not in STAGES:
        raise HTTPException(status_code=404, detail="Pipeline not found")
    return STAGES[pipeline_id]
```

### How to run the tests
```bash
pytest tests/s9/ -v
```

---

## Summary of Manual Steps

These steps must be done on GitHub (cannot be automated from CLI alone):

1. **Enable GitHub Actions** on your fork (Actions tab)
2. **Configure branch protection** on `main` (Settings → Branches)
3. **Create Pull Requests** via the GitHub UI

## Submission
```bash
git add -A
git commit -m "feat: add S9 CI/CD pipeline and endpoints"
git push origin main
```
