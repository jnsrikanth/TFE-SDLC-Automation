# Offline / Restricted Environment Build Guide

In highly secure Enterprise GCP environments, direct internet access (e.g., to download binaries or Python packages) is often restricted during the build process.

To overcome this, we use a **Vendoring Strategy**: we download all dependencies in a trusted environment (or via a proxy) *before* the build, package them into the build context, and then install them from local files.

## 1. Prerequisites

*   A machine with internet access (or configured proxy) to download:
    *   Terraform binaries (releases.hashicorp.com)
    *   Sentinel binaries (releases.hashicorp.com)
    *   Go binaries (go.dev)
    *   Python packages (PyPI)
*   Docker installed.

## 2. Vendor Dependencies

**NOTE:** The `vendor/` directory is already populated and committed to this repository. You do **not** need to run the download script unless you are updating dependencies.

If you need to update dependencies (e.g., new Terraform version), run:

```bash
./scripts/vendor_dependencies.sh
```

This will update:
*   `vendor/bin/terraform.zip`
*   `vendor/bin/sentinel.zip`
*   `vendor/bin/go.tar.gz`
*   `vendor/python/*.whl` (Python wheels)

## 3. Build Docker Image

Use the `Dockerfile.offline` which is configured to use these local assets instead of downloading them.

```bash
docker build -f Dockerfile.offline -t tfe-sdlc-agent:offline .
```

## 4. Cloud Build Configuration

If using Google Cloud Build, ensure your `cloudbuild.yaml` uses this Dockerfile and includes the `vendor/` directory in the upload.

**Example `cloudbuild.yaml`:**

```yaml
steps:
  # Build the container image using the offline Dockerfile
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-f', 'Dockerfile.offline', '-t', 'gcr.io/$PROJECT_ID/tfe-sdlc-agent', '.']

  # Push the container image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/tfe-sdlc-agent']

images:
  - 'gcr.io/$PROJECT_ID/tfe-sdlc-agent'
```

**Note:** You must run `./scripts/vendor_dependencies.sh` *before* submitting the build to Cloud Build.

```bash
# 1. Vendor dependencies
./scripts/vendor_dependencies.sh

# 2. Submit build (uploads vendor/ dir as part of context)
gcloud builds submit --config cloudbuild.yaml .
```

## 5. Base Image Considerations

The `Dockerfile.offline` uses `python:3.11-slim`. In a restricted environment, you may need to change this to a hardened image from your internal Artifact Registry.

Example:
```dockerfile
FROM us-central1-docker.pkg.dev/my-project/my-repo/python:3.11-hardened
```
