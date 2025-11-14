# Docker Build Notes

## Fixed Issues

### ✅ Dockerfile Build Arguments
The original Dockerfile was missing default values for build arguments, causing the error:
```
ERROR: failed to build: failed to solve: failed to parse stage name "ruby:-slim-bullseye"
```

**Fixed:** Added default values to all ARG variables in `Dockerfile`:
- `RUBY_VERSION=3.3.5`
- `APP_ENV=production`
- `PG_MAJOR=15`
- `NODE_MAJOR=16`
- `BUNDLER_VERSION=2.3.26`
- `YARN_VERSION=1.13.0`

## Current Issues

### ⚠️ Missing .docker-files Directory
The Dockerfile references scripts in `.docker-files/` directory which doesn't exist:
- `/docker-files/deps.sh`
- `/docker-files/pg.sh`
- `/docker-files/node.sh`

**Solutions:**

1. **Use Dockerfile.production** (Recommended)
   - A simplified production-ready Dockerfile that doesn't require `.docker-files`
   - Use this for cloud deployments (Railway, Render, Fly.io, etc.)

2. **Create the missing scripts** (If you need the original Dockerfile)
   - Create `.docker-files/deps.sh` - installs system dependencies
   - Create `.docker-files/pg.sh` - installs PostgreSQL client
   - Create `.docker-files/node.sh` - installs Node.js and Yarn

## Recommended Approach

For cloud deployments, use **Dockerfile.production**:

```bash
# Build with production Dockerfile
docker build -f Dockerfile.production -t chaskiq:latest .

# Or specify in your platform's config
# Railway, Render, Fly.io will auto-detect Dockerfile.production
```

## Platform-Specific Notes

### Railway
- Will auto-detect Dockerfile
- Can specify: `"dockerfile": "Dockerfile.production"` in `railway.json`

### Render
- Set `dockerfilePath: Dockerfile.production` in `render.yaml`

### Fly.io
- Use `dockerfile = "Dockerfile.production"` in `fly.toml`

### Google Cloud Run (Your Current Platform)
- Update your build command to use:
  ```bash
  gcloud builds submit --tag gcr.io/PROJECT_ID/chaskiq --file Dockerfile.production
  ```

## Testing Locally

```bash
# Build the image
docker build -f Dockerfile.production -t chaskiq:latest .

# Run locally (requires PostgreSQL and Redis)
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/db \
  -e REDIS_URL=redis://host:6379/0 \
  -e SECRET_KEY_BASE=your-secret-key \
  chaskiq:latest
```

