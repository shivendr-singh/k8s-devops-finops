# Kubernetes DevOps FinOps Assignment Documentation

## Requirement Understanding

The assignment requires a Kubernetes-based two-tier solution composed of one service/API tier and one database tier. The main expectation is not only to make the application work, but also to demonstrate sound Kubernetes design, deployment automation, resilience, configuration management, and cost-awareness.

### Functional Understanding

The service tier must expose an externally reachable endpoint. Whenever that endpoint is invoked, the service should connect to the database tier, fetch records, and return them to the caller. For this implementation, the service is a Node.js and TypeScript API built with Express and PostgreSQL connectivity through the `pg` driver.

The database tier must contain one table with seeded records and preserve those records even if the database pod is deleted and recreated. This means the database cannot rely on ephemeral container storage.

### Kubernetes Understanding

The assignment explicitly asks for:

- External exposure only for the service/API tier
- Internal-only access for the database tier
- Four service pods
- One database pod
- Rolling update support for the service tier
- Persistent storage for the database tier
- ConfigMap usage for configuration externalization
- Secret usage for sensitive values
- No pod IP based communication between tiers
- Ingress-based exposure for the service tier
- Demonstration of self-healing and autoscaling behavior

### FinOps Understanding

The assignment also expects resource-conscious design. That means the solution must define CPU and memory requests and limits for the service tier, identify cost optimization opportunities, and use observed metrics to justify or refine resource settings.

This turns the task into more than a basic deployment exercise. The final deliverable needs to show technical correctness, operational readiness, and cost-awareness together.

## Assumptions

The following assumptions were used while designing and implementing the solution:

1. The solution will run on a Kubernetes cluster where an ingress controller is available.
2. Metrics Server is installed so the Horizontal Pod Autoscaler can scale on CPU and memory utilization.
3. A default Kubernetes storage class exists for dynamic volume provisioning.
4. Docker images are pushed to Docker Hub before deployment.
5. The environment allows standard Kubernetes resources such as Deployment, StatefulSet, Service, Ingress, Secret, ConfigMap, HPA, PVC, and NetworkPolicy.
6. PostgreSQL is acceptable as the database technology because the assignment allows any suitable stack.
7. A single database replica is sufficient because the assignment asks for one database pod and does not require high availability for the data tier.
8. The service must remain at a minimum of four pods to satisfy the assignment requirement even when actual traffic is low.
9. The ingress hostname can be changed depending on whether the cluster is local, on Minikube, or on a cloud environment.
10. The proof of compliance will be demonstrated through Kubernetes commands, API calls, and scripted steps rather than through external observability platforms.

## Solution Overview

### High-Level Design

The implemented solution is a two-tier architecture:

- A stateless service/API tier built with Node.js, TypeScript, and Express
- A stateful PostgreSQL database tier deployed inside the same Kubernetes namespace

The service exposes `/api/records`, connects to PostgreSQL using a connection pool, retrieves seeded workload records, and returns them as JSON. The service does not use hard-coded infrastructure details. Instead, it reads configuration from Kubernetes ConfigMaps and Secrets.

### Application Design

The API application is intentionally lightweight so the focus stays on Kubernetes, DevOps, and FinOps concerns rather than business complexity. The code includes:

- `/healthz` for liveness checks
- `/readyz` for readiness checks
- `/api/records` for fetching database records
- Graceful shutdown handling for pod termination events
- Connection pooling for efficient database access

This design supports rolling updates, pod restarts, and autoscaling more safely than a minimal single-endpoint script would.

### Kubernetes Design

The Kubernetes implementation is organized as follows:

- `Namespace` isolates all assignment resources
- `Deployment` manages the service/API tier with 4 replicas
- `Service` exposes the API internally within the cluster
- `Ingress` exposes the API externally
- `HorizontalPodAutoscaler` scales the API based on CPU and memory
- `ConfigMap` stores non-sensitive configuration
- `Secret` stores the PostgreSQL password
- `StatefulSet` manages the PostgreSQL pod with stable identity
- `PersistentVolumeClaim` preserves PostgreSQL data
- `Headless Service` gives stable network identity to PostgreSQL
- `NetworkPolicy` restricts database access to API pods only

This separation keeps the architecture aligned with Kubernetes best practices and with the assignment’s explicit requirements.

### Communication Flow

The request flow is:

1. A client calls the API through the Ingress URL.
2. The Ingress routes the request to the `records-api` Service.
3. The Service load-balances the request to one of the four API pods.
4. The API pod uses the PostgreSQL service DNS name `postgres` to connect to the database tier.
5. PostgreSQL returns the records.
6. The API serializes the response and sends it back to the client.

This approach avoids direct pod IP communication and keeps the service discovery model stable even when pods are recreated.

### Reliability And Operations

The solution is designed so the required demonstrations are natural outcomes of the resource choices:

- API pod deletion is handled by the Deployment controller, which recreates missing pods
- Database pod deletion is handled by the StatefulSet controller, which restores `postgres-0`
- Database data persists because the volume is attached to a PVC rather than container storage
- Rolling updates are supported on the API tier through Deployment strategy settings
- Health checks protect rollouts and restart behavior
- HPA can increase service capacity during load

### FinOps Alignment

The service tier includes explicit resource requests and limits:

- CPU request: `100m`
- CPU limit: `500m`
- Memory request: `128Mi`
- Memory limit: `256Mi`

These values provide a starting point for cost control and can be refined using `kubectl top` and HPA observations. The implementation also includes a load-generation job and proof script so metric-based right-sizing can be demonstrated in a repeatable way.

### Delivery And Demonstration Support

To make the assignment easier to execute and prove, the repository includes:

- `scripts/build-push.ps1` to build and push the Docker image
- `scripts/deploy.ps1` to create the secret safely and deploy the manifests
- `scripts/prove-requirements.ps1` to walk through the key proof points

This reduces manual setup errors and makes the final screen recording more consistent.

## Justification for the Resources Utilized

### Node.js And TypeScript

Node.js with TypeScript was chosen because it allows fast development of a small API while still providing strong maintainability. TypeScript improves readability and correctness, especially around configuration handling and database access. For this assignment, it offers a good balance between simplicity and professional structure.

### Express API Service

Express is sufficient for the required API because the service only needs a few endpoints, health probes, and database integration. A heavier framework would add complexity without improving the assignment outcome.

### PostgreSQL

PostgreSQL is a mature, production-proven relational database and is well suited for the requirement of storing structured records in one table. It is also straightforward to seed with initialization SQL and works cleanly with persistent volumes in Kubernetes.

### Deployment For The API Tier

Deployment is the correct controller for the service tier because the API is stateless and needs:

- Four replicas
- Rolling updates
- Self-healing
- HPA compatibility

These are all native strengths of Deployment.

### StatefulSet For The Database Tier

StatefulSet is the correct controller for PostgreSQL because the database is stateful and needs:

- Stable naming
- Stable storage association
- Predictable recovery behavior after pod deletion

Using a Deployment for the database would be weaker from a persistence and identity standpoint.

### ConfigMap

ConfigMap is used to externalize database host, port, database name, username, and API port settings. This satisfies the requirement that database-related configuration be provided from outside the application code and pod definition logic.

This also improves portability because the same container image can be deployed across environments with different runtime configuration.

### Secret

Secret is used for the PostgreSQL password because the assignment explicitly requires that the database password should not be clearly visible in Kubernetes YAML files. In this repository, the actual secret is created at deployment time rather than being hard-coded into committed manifests.

### Service Resources

Two Service patterns are used:

- A standard Service for the API so traffic can be routed consistently to the replica set
- A headless Service for PostgreSQL so the StatefulSet can keep stable service discovery semantics

This matches the different networking needs of stateless and stateful workloads.

### Ingress

Ingress was selected because the assignment explicitly asks for the service/API tier to be exposed externally using Ingress. It is also more flexible and realistic than exposing the API directly with `NodePort`.

### Persistent Volume Claim

The PVC is necessary because the database data must survive pod deletion and re-creation. Without persistent storage, the demonstration of data retention would fail.

### Horizontal Pod Autoscaler

HPA is required because the assignment asks for autoscaling demonstration on the service tier. It was configured on resource metrics so the scaling decision can be explained and validated through standard Kubernetes tooling.

### NetworkPolicy

Although the assignment only says the database should be accessible within the cluster, a NetworkPolicy strengthens that requirement by limiting inbound database access to API pods only. This is a stronger and more explicit implementation of internal-only access.

### Resource Requests And Limits

CPU and memory requests/limits were included because:

- They are explicitly required by the FinOps portion of the assignment
- They support better bin-packing and scheduling behavior
- They prevent accidental overconsumption
- They provide the baseline for meaningful HPA behavior

### Automation Scripts

The PowerShell scripts are justified because they improve repeatability for:

- Building and publishing images
- Secure secret creation at deployment time
- Running the required proof and demonstration flow

For an assignment with a mandatory screen recording and multiple operational proof points, automation meaningfully reduces risk during final submission.

## Additional Notes

### Requirement-to-Implementation Mapping

| Requirement | Implementation |
| --- | --- |
| API exposed outside cluster | `k8s/api-ingress.yaml` |
| API replica count 4 | `k8s/api-deployment.yaml` |
| Rolling updates for API | Deployment rolling update strategy |
| API self-healing | Deployment with Kubernetes reconciliation and probes |
| HPA on service tier | `k8s/api-hpa.yaml` |
| Database internal only | Headless PostgreSQL service plus NetworkPolicy |
| Database persistence | StatefulSet volume claim template |
| 5 to 10 records in one table | `k8s/postgres-init-configmap.yaml` |
| ConfigMap usage | `k8s/api-configmap.yaml` |
| Secret usage | runtime-created `app-secret` documented by `k8s/app-secret.template.yaml` |
| No pod IP communication | API connects using the `postgres` service DNS name |

### Cost Optimization Opportunities

1. Right-size API requests and limits after observing real metrics from `kubectl top`.
2. Keep the database single-node for the assignment rather than over-engineering a more expensive HA topology.
3. Use HPA to scale the API only when required by actual traffic.
4. Delete the cluster after recording the deliverables to avoid unnecessary cost.
5. Prefer small worker nodes or lower-cost dev/test capacity for this non-production scenario.
