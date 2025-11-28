# Cloud Run Deployment Procedure

This document outlines the steps to deploy the `tfe-sdlc-agent` Docker image to Google Cloud Run.

## Prerequisites
- **Docker Image**: The image must be built and pushed to Google Container Registry (GCR).
  - Image URI: `gcr.io/moe-app-bfsi-1757248254/tfe-sdlc-agent`
- **GCloud CLI**: Authenticated and configured for project `moe-app-bfsi-1757248254`.

## Deployment Steps

### Option 1: Command Line (Recommended)

Run the following command to deploy the service. This command sets the necessary environment variables and configures the region.

```bash
gcloud run deploy tfe-sdlc-agent \
  --image gcr.io/moe-app-bfsi-1757248254/tfe-sdlc-agent \
  --platform managed \
  --region us-central1 \
  --project moe-app-bfsi-1757248254 \
  --allow-unauthenticated \
  --set-env-vars "GEMINI_API_KEY=${GEMINI_API_KEY},GCP_PROJECT_ID=moe-app-bfsi-1757248254,GCP_LOCATION=us-central1"
```

> **Note**: Replace `${GEMINI_API_KEY}` with your actual API key, or ensure it is set in your current shell environment.

### Option 2: Google Cloud Console

1.  Navigate to **Cloud Run** in the Google Cloud Console.
2.  Click **CREATE SERVICE**.
3.  **Container image URL**: Click "SELECT" and choose `tfe-sdlc-agent` from the Container Registry.
4.  **Service name**: `tfe-sdlc-agent`.
5.  **Region**: `us-central1`.
6.  **Authentication**: Choose "Allow unauthenticated invocations" (or "Require authentication" if you want to restrict access).
7.  Expand **Container, Networking, Security**.
8.  Under **Variables & Secrets**, add the following Environment variables:
    - `GEMINI_API_KEY`: [Your API Key]
    - `GCP_PROJECT_ID`: `moe-app-bfsi-1757248254`
    - `GCP_LOCATION`: `us-central1`
9.  Click **CREATE**.

## Verification

After deployment, Cloud Run will provide a **Service URL**.

1.  Open the Service URL in your browser.
2.  You should see the application output (or a health check response if implemented).
3.  View logs in the "Logs" tab of the Cloud Run service detail page to ensure the agent is starting correctly.
