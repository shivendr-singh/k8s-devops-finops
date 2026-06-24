param(
  [string]$Namespace = "nagp-assignment",
  [string]$ImageRepo = "shivendra1s/records-api",
  [string]$ImageTag = "1.0.0",
  [string]$PostgresPassword = $env:POSTGRES_PASSWORD,
  [string]$IngressHost = "records.127.0.0.1.nip.io"
)

$ErrorActionPreference = "Stop"

if (-not $PostgresPassword) {
  throw "Provide -PostgresPassword or set POSTGRES_PASSWORD before deployment."
}

Write-Host "Creating or updating namespace $Namespace"
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

Write-Host "Creating or updating database secret"
kubectl create secret generic app-secret `
  --namespace $Namespace `
  --from-literal=POSTGRES_PASSWORD=$PostgresPassword `
  --dry-run=client -o yaml | kubectl apply -f -

Write-Host "Applying Kubernetes manifests"
kubectl apply -k .\k8s

Write-Host "Setting API image to $ImageRepo`:$ImageTag"
kubectl set image deployment/records-api records-api="$ImageRepo`:$ImageTag" -n $Namespace

$ingressPatch = @{
  spec = @{
    rules = @(
      @{
        host = $IngressHost
        http = @{
          paths = @(
            @{
              path = "/"
              pathType = "Prefix"
              backend = @{
                service = @{
                  name = "records-api"
                  port = @{
                    number = 80
                  }
                }
              }
            }
          )
        }
      }
    )
  }
} | ConvertTo-Json -Depth 10 -Compress

Write-Host "Patching ingress host to $IngressHost"
kubectl patch ingress records-api -n $Namespace --type merge -p $ingressPatch

Write-Host "Waiting for API deployment rollout"
kubectl rollout status deployment/records-api -n $Namespace --timeout=240s

Write-Host "Waiting for PostgreSQL statefulset rollout"
kubectl rollout status statefulset/postgres -n $Namespace --timeout=240s

Write-Host "Deployment summary"
kubectl get all,pvc,ingress,hpa -n $Namespace

