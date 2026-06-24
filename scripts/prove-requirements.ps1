param(
  [string]$Namespace = "nagp-assignment",
  [string]$ApiUrl = "http://records.127.0.0.1.nip.io/api/records",
  [string]$ReportPath = ".\outputs\proof-report.md",
  [switch]$RunLoad,
  [switch]$PauseBetweenSteps
)

$ErrorActionPreference = "Stop"

$reportDirectory = Split-Path -Parent $ReportPath
if ($reportDirectory) {
  New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
}

Set-Content -Path $ReportPath -Value "# Kubernetes Assignment Proof Report`n"

function Add-Section {
  param(
    [string]$Title
  )

  Add-Content -Path $ReportPath -Value "`n## $Title`n"
  Write-Host "`n=== $Title ===`n"

  if ($PauseBetweenSteps) {
    Read-Host "Press Enter to continue"
  }
}

function Log-Command {
  param(
    [string]$Label,
    [scriptblock]$Action
  )

  Write-Host ">> $Label"
  $output = & $Action 2>&1 | Out-String
  Write-Host $output
  $reportBlock = "### $Label`n" + '```text' + "`n$output`n" + '```'
  Add-Content -Path $ReportPath -Value $reportBlock
  return $output
}

function Wait-ForApiReplicaRecovery {
  param(
    [int]$ExpectedReplicas = 4,
    [int]$TimeoutSeconds = 240
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $ready = kubectl get deployment records-api -n $Namespace -o jsonpath='{.status.readyReplicas}'
    if ($ready -eq "$ExpectedReplicas") {
      return
    }

    Start-Sleep -Seconds 5
  }

  throw "Timed out waiting for records-api to recover to $ExpectedReplicas ready replicas."
}

function Wait-ForPodReady {
  param(
    [string]$PodName,
    [int]$TimeoutSeconds = 240
  )

  kubectl wait --for=condition=Ready "pod/$PodName" -n $Namespace --timeout="$($TimeoutSeconds)s"
}

Add-Section "Current Objects"
Log-Command "kubectl get all,pvc,ingress,hpa -n $Namespace" {
  kubectl get all,pvc,ingress,hpa -n $Namespace
}

Add-Section "API Reachability And Seed Data"
Log-Command "curl $ApiUrl" {
  curl.exe -s $ApiUrl
}

Add-Section "API Deployment Requirements"
Log-Command "Replica count, strategy, and resource limits" {
  $deployment = kubectl get deployment records-api -n $Namespace -o json | ConvertFrom-Json
  $container = $deployment.spec.template.spec.containers[0]
  @(
    "replicas=$($deployment.spec.replicas)"
    "strategy=$($deployment.spec.strategy.type)"
    "cpu-request=$($container.resources.requests.cpu)"
    "cpu-limit=$($container.resources.limits.cpu)"
    "memory-request=$($container.resources.requests.memory)"
    "memory-limit=$($container.resources.limits.memory)"
  ) -join " "
}
Log-Command "Environment sources from ConfigMap and Secret" {
  kubectl describe deployment records-api -n $Namespace
}

Add-Section "Database Internal-Only Requirement"
Log-Command "PostgreSQL service type and DNS name" {
  $service = kubectl get svc postgres -n $Namespace -o json | ConvertFrom-Json
  "name=$($service.metadata.name) type=$($service.spec.type) clusterIP=$($service.spec.clusterIP)"
}
Log-Command "Network policy restricting access to PostgreSQL" {
  kubectl get networkpolicy postgres-allow-api-only -n $Namespace -o yaml
}

Add-Section "Rolling Update Support"
Log-Command "Restarting API deployment to show rollout" {
  kubectl rollout restart deployment/records-api -n $Namespace
  kubectl rollout status deployment/records-api -n $Namespace --timeout=240s
  kubectl rollout history deployment/records-api -n $Namespace
}

Add-Section "API Self-Healing"
$apiPod = (kubectl get pods -n $Namespace -l app=records-api -o jsonpath='{.items[0].metadata.name}')
Log-Command "Deleting API pod $apiPod" {
  kubectl delete pod $apiPod -n $Namespace
}
Wait-ForApiReplicaRecovery
Log-Command "API pods after recovery" {
  kubectl get pods -n $Namespace -l app=records-api -o wide
}

Add-Section "Database Persistence And Self-Healing"
Log-Command "Insert persistence marker row in PostgreSQL" {
  $postgresPassword = (kubectl exec -n $Namespace postgres-0 -- printenv POSTGRES_PASSWORD).Trim()
  $postgresUser = (kubectl exec -n $Namespace postgres-0 -- printenv POSTGRES_USER).Trim()
  $postgresDatabase = (kubectl exec -n $Namespace postgres-0 -- printenv POSTGRES_DB).Trim()
  $insertStatement = "INSERT INTO finops_workloads (name, category, monthly_cost) VALUES ('persistence-check', 'validation', 12.34) ON CONFLICT (name) DO NOTHING;"

  kubectl exec -n $Namespace postgres-0 -- env "PGPASSWORD=$postgresPassword" `
    psql -U $postgresUser -d $postgresDatabase -c $insertStatement
}
Log-Command "Read records before deleting the database pod" {
  curl.exe -s $ApiUrl
}
Log-Command "Delete PostgreSQL pod to trigger StatefulSet recovery" {
  kubectl delete pod postgres-0 -n $Namespace
  Wait-ForPodReady -PodName "postgres-0" -TimeoutSeconds 240
}
Log-Command "Read records after PostgreSQL recovery" {
  curl.exe -s $ApiUrl
}

Add-Section "HPA And FinOps Evidence"
Log-Command "Current HPA definition" {
  kubectl get hpa records-api -n $Namespace
}

if ($RunLoad) {
  Log-Command "Triggering load generator job" {
    kubectl delete job records-api-load-generator -n $Namespace --ignore-not-found
    kubectl apply -f .\k8s\optional\api-load-generator-job.yaml
  }

  Start-Sleep -Seconds 20

  Log-Command "Resource usage from metrics server" {
    kubectl top pods -n $Namespace
  }

  Log-Command "HPA status during or after generated load" {
    kubectl get hpa records-api -n $Namespace -o wide
  }
}

Add-Section "Requirement Mapping Summary"
$summaryLines = @(
  '| Requirement | Proof |',
  '| --- | --- |',
  ('| API externally accessible | curl ' + $ApiUrl + ' |'),
  '| API replica count 4 | kubectl get deployment records-api |',
  '| Rolling updates | kubectl rollout restart/status/history deployment/records-api |',
  '| API self-healing | delete one API pod and confirm recovery |',
  '| API HPA | kubectl get hpa records-api and optional generated load |',
  '| Database internal only | kubectl get svc postgres and NetworkPolicy |',
  '| Database persistence | insert marker row, delete postgres-0, fetch records again |',
  '| ConfigMap usage | kubectl describe deployment records-api |',
  '| Secret usage | kubectl describe deployment records-api and runtime-created app-secret |',
  '| Requests and limits | kubectl get deployment records-api -o jsonpath=... |'
)
Add-Content -Path $ReportPath -Value ($summaryLines -join "`n")

Write-Host "Proof report written to $ReportPath"
