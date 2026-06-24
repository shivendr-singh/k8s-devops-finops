# Kubernetes Assignment Proof Report


## Current Objects

### kubectl get all,pvc,ingress,hpa -n nagp-assignment
```text
NAME                                   READY   STATUS      RESTARTS   AGE
pod/postgres-0                         1/1     Running     0          3m16s
pod/records-api-5d7d4f6f87-lhklc       1/1     Running     0          4m10s
pod/records-api-5d7d4f6f87-s2mcx       1/1     Running     0          5m
pod/records-api-5d7d4f6f87-w7nr8       1/1     Running     0          4m45s
pod/records-api-5d7d4f6f87-zkkck       1/1     Running     0          4m42s
pod/records-api-load-generator-465kc   0/1     Completed   0          2m36s
pod/records-api-load-generator-nsqgf   0/1     Completed   0          2m36s
pod/records-api-load-generator-vf5jq   0/1     Completed   0          2m37s
pod/records-api-load-generator-x2vgv   0/1     Completed   0          2m36s

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/postgres      ClusterIP   None           <none>        5432/TCP   24m
service/records-api   ClusterIP   10.109.60.78   <none>        80/TCP     24m

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/records-api   4/4     4            4           24m

NAME                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/records-api-5d7d4f6f87   4         4         4       5m
replicaset.apps/records-api-6745d948     0         0         0       10m
replicaset.apps/records-api-7df7f8799b   0         0         0       19m
replicaset.apps/records-api-858bd5d849   0         0         0       24m

NAME                        READY   AGE
statefulset.apps/postgres   1/1     24m

NAME                                              REFERENCE                TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/records-api   Deployment/records-api   cpu: 1%/70%, memory: 11%/75%   4         10        4          24m

NAME                                   STATUS     COMPLETIONS   DURATION   AGE
job.batch/records-api-load-generator   Complete   4/4           18s        2m37s

NAME                                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/postgres-data-postgres-0   Bound    pvc-23481c7f-0785-4eb2-9a17-fb8a200dfb6d   1Gi        RWO            standard       <unset>                 24m

NAME                                    CLASS   HOSTS                      ADDRESS        PORTS   AGE
ingress.networking.k8s.io/records-api   nginx   records.127.0.0.1.nip.io   192.168.49.2   80      24m

```

## API Reachability And Seed Data

### curl http://records.192.168.49.2.nip.io/api/records
```text

```

## API Deployment Requirements

### Replica count, strategy, and resource limits
```text
replicas=4 strategy=RollingUpdate cpu-request=100m cpu-limit=500m memory-request=128Mi memory-limit=256Mi

```
### Environment sources from ConfigMap and Secret
```text
Name:                   records-api
Namespace:              nagp-assignment
CreationTimestamp:      Wed, 24 Jun 2026 16:40:11 +0530
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 4
Selector:               app=records-api
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 1 max surge
Pod Template:
  Labels:       app=records-api
                tier=service
  Annotations:  kubectl.kubernetes.io/restartedAt: 2026-06-24T17:00:00+05:30
  Containers:
   records-api:
    Image:      shivendra1s/records-api:1.0.0
    Port:       8080/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     500m
      memory:  256Mi
    Requests:
      cpu:      100m
      memory:   128Mi
    Liveness:   http-get http://:http/healthz delay=20s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:http/readyz delay=10s timeout=1s period=5s #success=1 #failure=3
    Environment Variables from:
      api-config  ConfigMap  Optional: false
    Environment:
      DB_PASSWORD:  <set to the key 'POSTGRES_PASSWORD' in secret 'app-secret'>  Optional: false
    Mounts:         <none>
  Volumes:          <none>
  Node-Selectors:   <none>
  Tolerations:      <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  records-api-858bd5d849 (0/0 replicas created), records-api-7df7f8799b (0/0 replicas created), records-api-6745d948 (0/0 replicas created)
NewReplicaSet:   records-api-5d7d4f6f87 (4/4 replicas created)
Events:
  Type    Reason             Age                   From                   Message
  ----    ------             ----                  ----                   -------
  Normal  ScalingReplicaSet  25m                   deployment-controller  Scaled up replica set records-api-858bd5d849 from 0 to 4
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled up replica set records-api-7df7f8799b from 0 to 1
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled down replica set records-api-858bd5d849 from 4 to 3
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled up replica set records-api-7df7f8799b from 1 to 2
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled down replica set records-api-858bd5d849 from 3 to 2
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled up replica set records-api-7df7f8799b from 2 to 3
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled down replica set records-api-858bd5d849 from 2 to 1
  Normal  ScalingReplicaSet  20m                   deployment-controller  Scaled up replica set records-api-7df7f8799b from 3 to 4
  Normal  ScalingReplicaSet  19m                   deployment-controller  Scaled down replica set records-api-858bd5d849 from 1 to 0
  Normal  ScalingReplicaSet  5m19s (x16 over 11m)  deployment-controller  (combined from similar events): Scaled down replica set records-api-6745d948 from 1 to 0

```

## Database Internal-Only Requirement

### PostgreSQL service type and DNS name
```text
name=postgres type=ClusterIP clusterIP=None

```
### Network policy restricting access to PostgreSQL
```text
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.k8s.io/v1","kind":"NetworkPolicy","metadata":{"annotations":{},"name":"postgres-allow-api-only","namespace":"nagp-assignment"},"spec":{"ingress":[{"from":[{"podSelector":{"matchLabels":{"app":"records-api"}}}],"ports":[{"port":5432,"protocol":"TCP"}]}],"podSelector":{"matchLabels":{"app":"postgres"}},"policyTypes":["Ingress"]}}
  creationTimestamp: "2026-06-24T11:10:11Z"
  generation: 1
  name: postgres-allow-api-only
  namespace: nagp-assignment
  resourceVersion: "35015"
  uid: 13a3f507-ad0a-4bcf-a68b-257c662cbace
spec:
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: records-api
    ports:
    - port: 5432
      protocol: TCP
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress

```

## Rolling Update Support

### Restarting API deployment to show rollout
```text
deployment.apps/records-api restarted
Waiting for deployment "records-api" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "records-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "records-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "records-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "records-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "records-api" rollout to finish: 3 of 4 updated replicas are available...
Waiting for deployment "records-api" rollout to finish: 3 of 4 updated replicas are available...
deployment "records-api" successfully rolled out
deployment.apps/records-api 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
4         <none>
5         <none>


```

## API Self-Healing

### Deleting API pod records-api-66f8c5cb-2lfs5
```text
pod "records-api-66f8c5cb-2lfs5" deleted

```
### API pods after recovery
```text
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
records-api-66f8c5cb-8bgj8   1/1     Running   0          17s   10.244.0.86   minikube   <none>           <none>
records-api-66f8c5cb-dpxsq   1/1     Running   0          48s   10.244.0.84   minikube   <none>           <none>
records-api-66f8c5cb-qhcg8   1/1     Running   0          62s   10.244.0.82   minikube   <none>           <none>
records-api-66f8c5cb-v9wpw   1/1     Running   0          46s   10.244.0.85   minikube   <none>           <none>

```

## Database Persistence And Self-Healing

### Insert persistence marker row in PostgreSQL
```text
INSERT 0 0

```
### Read records before deleting the database pod
```text

```
### Delete PostgreSQL pod to trigger StatefulSet recovery
```text
pod "postgres-0" deleted
pod/postgres-0 condition met

```
### Read records after PostgreSQL recovery
```text

```

## HPA And FinOps Evidence

### Current HPA definition
```text
NAME          REFERENCE                TARGETS                               MINPODS   MAXPODS   REPLICAS   AGE
records-api   Deployment/records-api   cpu: <unknown>/70%, memory: 11%/75%   4         10        4          28m

```
### Triggering load generator job
```text
job.batch "records-api-load-generator" deleted
job.batch/records-api-load-generator created

```
### Resource usage from metrics server
```text
NAME                         CPU(cores)   MEMORY(bytes)   
postgres-0                   8m           24Mi            
records-api-66f8c5cb-8bgj8   3m           14Mi            
records-api-66f8c5cb-dpxsq   2m           15Mi            
records-api-66f8c5cb-qhcg8   2m           15Mi            
records-api-66f8c5cb-v9wpw   2m           14Mi            

```
### HPA status during or after generated load
```text
NAME          REFERENCE                TARGETS                        MINPODS   MAXPODS   REPLICAS   AGE
records-api   Deployment/records-api   cpu: 2%/70%, memory: 11%/75%   4         10        4          29m

```

## Requirement Mapping Summary

| Requirement | Proof |
| --- | --- |
| API externally accessible | curl http://records.192.168.49.2.nip.io/api/records |
| API replica count 4 | kubectl get deployment records-api |
| Rolling updates | kubectl rollout restart/status/history deployment/records-api |
| API self-healing | delete one API pod and confirm recovery |
| API HPA | kubectl get hpa records-api and optional generated load |
| Database internal only | kubectl get svc postgres and NetworkPolicy |
| Database persistence | insert marker row, delete postgres-0, fetch records again |
| ConfigMap usage | kubectl describe deployment records-api |
| Secret usage | kubectl describe deployment records-api and runtime-created app-secret |
| Requests and limits | kubectl get deployment records-api -o jsonpath=... |
