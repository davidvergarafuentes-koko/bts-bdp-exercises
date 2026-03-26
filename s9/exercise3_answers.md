# Exercise 3: Building Docker Images in CI

## Objective
See how a CI pipeline builds a Docker image only after lint and tests pass, using job dependencies.

## Steps Performed

### 1. Replace the workflow
```bash
cp solutions/exercise3_docker.yml .github/workflows/ci.yml
```

### 2. Dockerfile reviewed
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 3. New workflow reviewed — Two jobs now
```yaml
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      # ... lint + test (same as exercise 2)

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
          context: ./app
          push: false
          tags: bts-bdp-app:latest
```

### 4. Push and observe
```bash
git add .github/workflows/ci.yml
git commit -m "feat: add Docker build job to CI"
git push origin main
```

**Observed in Actions:**
1. The `ci` job runs first (lint + test)
2. Only after `ci` passes, the `docker` job starts
3. GitHub shows the dependency graph visually

## Pipeline Visualization

```
┌──────────┐      ┌──────────┐
│    ci     │─────▶│  docker   │
│ lint+test │      │   build   │
└──────────┘      └──────────┘
```

## Key Concepts

| Concept | Description |
|---------|-------------|
| `needs: ci` | Creates a **dependency** — `docker` waits for `ci` to pass |
| `docker/setup-buildx-action@v3` | Sets up Docker Buildx for building images |
| `docker/build-push-action@v5` | Marketplace action to build (and optionally push) Docker images |
| `push: false` | Only **build** the image, don't push to a registry |
| `context: ./app` | The Docker build context is the `app/` directory |
| `tags: bts-bdp-app:latest` | Tags the built image |

## Questions & Answers

**Q: What does `needs: ci` do?**
A: It makes the `docker` job wait for the `ci` job to complete successfully before starting. If `ci` fails, `docker` is skipped.

**Q: Why is `push: false`?**
A: In this exercise we only verify the image builds correctly. In production, you'd push to Docker Hub, AWS ECR, or GitHub Container Registry.

**Q: Why use two separate jobs instead of one?**
A: Separation of concerns — CI validation and Docker building are independent tasks. They can also run on different runners and have different permissions.

**Q: What is Docker Buildx?**
A: An extended build tool for Docker that supports multi-platform builds, build caching, and other advanced features.

**Q: What is the real-world pipeline pattern here?**
A: Validate quality first (lint + test), then build the artifact (Docker image). This ensures you never build broken code.
