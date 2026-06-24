# Kubernetes DevOps FinOps Assignment

This repository contains a Node.js and TypeScript microservice backed by PostgreSQL, packaged with Docker and deployed to Kubernetes. The implementation is designed to satisfy the NAGP 2026 Band III workshop assignment for Kubernetes, DevOps, and FinOps.

## Stack

- Node.js 20
- TypeScript
- Express
- PostgreSQL 16
- Docker
- Kubernetes with Ingress and HPA

## Deliverable Links

- Repository URL: `https://github.com/shivendra1s/k8s-devops-finops`
- Docker Hub URL: `https://hub.docker.com/r/shivendra1s/records-api`
- Service API URL: `http://records.127.0.0.1.nip.io/api/records`
- Assignment Documentation: [docs/solution-overview.md](docs/solution-overview.md)

## Solution Layout

- `src/`: TypeScript API service
- `Dockerfile`: multi-stage build for the API image
- `k8s/`: Kubernetes manifests for namespace, configuration, secret, database, API, ingress, and HPA
- `k8s/optional/api-load-generator-job.yaml`: helper job for HPA and metrics demonstrations
- `scripts/`: PowerShell helpers for build, push, deployment, and requirement proofs
- `docs/solution-overview.md`: requirement understanding, assumptions, design choices, and FinOps notes

## API Endpoints

- `GET /`
- `GET /healthz`
- `GET /readyz`
- `GET /api/records`

## Local Development

1. Install dependencies with `npm install`.
2. Create a local PostgreSQL database that matches the Kubernetes configuration.
3. Export the required environment variables:

```powershell
$env:PORT="8080"
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="finopsdb"
$env:DB_USER="appuser"
$env:DB_PASSWORD="change-me-super-secret"
```

4. Start the API with `npm run dev`.

## Build And Push The API Image

Preferred flow:

```powershell
.\scripts\build-push.ps1 -DockerHubToken "<dockerhub-access-token>"
```

Manual equivalent:

```powershell
docker build -t shivendra1s/records-api:1.0.0 .
docker push shivendra1s/records-api:1.0.0
```

Use a Docker Hub access token instead of storing your password in the repo or shell history whenever possible.

## Kubernetes Deployment

1. Make sure an ingress controller and metrics server exist in the cluster.
2. Set a PostgreSQL password in your shell:

```powershell
$env:POSTGRES_PASSWORD="your-strong-postgres-password"
```

3. Deploy with the helper script:

```powershell
.\scripts\deploy.ps1
```

4. Manual equivalent:

```powershell
kubectl create secret generic app-secret --namespace nagp-assignment --from-literal=POSTGRES_PASSWORD=$env:POSTGRES_PASSWORD --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k k8s
```

5. Verify resources:

```powershell
kubectl get all -n nagp-assignment
kubectl get ingress -n nagp-assignment
kubectl get pvc -n nagp-assignment
kubectl get hpa -n nagp-assignment
```

## Proof And Demo Guide

Run the automated proof script:

```powershell
.\scripts\prove-requirements.ps1 -RunLoad -PauseBetweenSteps
```

This script:

- Verifies deployed objects
- Fetches the records through the API
- Confirms the API has 4 replicas and rolling update strategy
- Confirms the database is internal-only
- Shows ConfigMap and Secret references
- Deletes one API pod and waits for self-healing
- Inserts a persistence marker row, deletes the database pod, and verifies the data still exists
- Triggers HPA load and captures `kubectl top` plus HPA status
- Writes a markdown proof report to `outputs/proof-report.md`

If you are recording a screen capture, `-PauseBetweenSteps` gives you a clean checkpoint before each requirement proof.

## Manual Demonstration Guide

### Show API Data

```powershell
curl http://records.127.0.0.1.nip.io/api/records
```

### Show Service Self-Healing

```powershell
kubectl delete pod -n nagp-assignment -l app=records-api
kubectl get pods -n nagp-assignment -w
```

### Show Database Self-Healing And Persistence

```powershell
kubectl delete pod postgres-0 -n nagp-assignment
kubectl get pods -n nagp-assignment -w
curl http://records.127.0.0.1.nip.io/api/records
```

### Show HPA Scaling

```powershell
kubectl apply -f k8s/optional/api-load-generator-job.yaml
kubectl top pods -n nagp-assignment
kubectl get hpa -n nagp-assignment -w
```

## Notes Before Submission

- Replace the repository URL placeholder.
- Record the required screen capture after successful deployment.
- If your cluster is not local, change the ingress host in `k8s/api-ingress.yaml` and update the service URL above.
- `k8s/app-secret.template.yaml` is documentation only. The real secret is created by `scripts/deploy.ps1` or the manual `kubectl create secret` command.
