param(
  [string]$ImageRepo = "shivendra1s/records-api",
  [string]$ImageTag = "1.0.0",
  [string]$DockerHubUsername = "shivendra1s",
  [string]$DockerHubToken = $env:DOCKERHUB_TOKEN,
  [switch]$SkipLogin
)

$ErrorActionPreference = "Stop"
$image = "$ImageRepo`:$ImageTag"

Write-Host "Building image $image"
docker build -t $image .

if (-not $SkipLogin) {
  if (-not $DockerHubToken) {
    throw "Provide -DockerHubToken or set DOCKERHUB_TOKEN before running this script."
  }

  Write-Host "Logging in to Docker Hub as $DockerHubUsername"
  $DockerHubToken | docker login --username $DockerHubUsername --password-stdin
}

Write-Host "Pushing image $image"
docker push $image

Write-Host "Image published: $image"

