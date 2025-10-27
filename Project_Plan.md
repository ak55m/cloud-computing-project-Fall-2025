# CS 6343 – Cloud Computing (Group 4)

## Workflow on Kubernetes using Flask, Celery, RabbitMQ, PostgreSQL, and Flower

**Team Members:** Chacko Happy, Akeem Mohammed, Kunal Koshti, Ajwad Masood  
**Instructor:** Dr. Il-Yeng Kim  
**Date:** October 8, 2025

---

## Project Milestone 2

### 1) Solution Topology

This project is based on the open-source repository `asoucase/flask-celery-kubernetes-example`. The workflow models a realistic microservice data-processing pipeline composed of five interacting services:

| Tier | Component | Kubernetes Object | Key Role |
|------|-----------|-------------------|----------|
| T1 Ingest | RabbitMQ | StatefulSet (1 replica) + PVC (10 Gi) | Message broker queuing tasks from Flask to Celery |
| T2 Process | Celery Workers | Deployment (scalable 3-10 replicas) | Execute background tasks asynchronously |
| T3 Store | PostgreSQL | StatefulSet (1 replica) + PVC (20 Gi) | Persistent storage for task results |
| T4 Visualize | Flower Dashboard | Deployment (1 replica) | Operational visibility into Celery queues and workers |
| T5 Interface | Flask API (Producer) | Deployment (2 replicas) | Web entrypoint for submitting tasks and viewing results |

#### Ingress Controller

A single NGINX Ingress resource provides HTTP routing:
- `/api` → Flask service (port 5000)
- `/flower` → Flower Service (port 5555)

---

### 2) Containers & Images

| Component | Base Image | Configuration |
|-----------|------------|---------------|
| Flask API | `asoucase/flask_app` | Add environment variables (RABBITMQ_URL, DATABASE_URL) and a ClusterIP Service so the API can communicate reliably with RabbitMQ and PostgreSQL over Kubernetes DNS. |
| Celery Worker | `asoucase/celery-worker` | Convert from Docker Compose to a scalable Kubernetes Deployment with 2–3 replicas and an HPA so workers can expand automatically under load. |
| RabbitMQ | `rabbitmq` | Deploy it as a StatefulSet with a PersistentVolumeClaim to preserve message queues and avoid losing tasks on pod restarts. |
| PostgreSQL | `postgres:10-alpine` | Add a new StatefulSet with persistent storage and secure credentials in a Kubernetes Secret to provide durable task-result storage. |
| Flower | `arturosoucase/flask-celery-example-flower` | Create a Service and Ingress route (/flower) so the built-in monitoring dashboard is accessible from outside the cluster. |

---

### 3) Resource Model (Requests/Limits & QoS)

RabbitMQ and PostgreSQL require consistent availability, so they receive guaranteed CPU and memory allocations. Celery workers are stateless and horizontally scalable, so their replicas increase under high message queue depth.

| Component | CPU/Memory Requests | CPU/Memory Limits | QoS Class |
|-----------|---------------------|-------------------|-----------|
| RabbitMQ | 250m/512Mi | 500m/1Gi | Burstable |
| Celery Worker | 500m/512Mi | 1 CPU/1Gi | BestEffort |
| Flask API | 300m/256Mi | 500m/512Mi | Burstable |
| PostgreSQL | 1 CPU/2Gi | 2 CPU/4Gi | Guaranteed |
| Flower | 100m/128Mi | 300m/256Mi | Burstable |

---

### 4) Scheduling Strategy (Affinity | Taints | Topology)

Celery workers need to be evenly distributed across nodes. PostgreSQL and RabbitMQ need to be scheduled close to each other to reduce network latency.

**Node Labels/Taints:**
- Nodes labeled `role=stateful` host PostgreSQL and RabbitMQ.
- Nodes labeled `role=stateless` run Flask, Celery, and Flower pods.

**Anti-Affinity:** Celery workers use pod anti-affinity to spread across nodes, improving parallelism and fault isolation.

**Topology Spread:** Ensures even distribution of worker pods by `kubernetes.io/hostname`.

**Priority Classes:** PostgreSQL > RabbitMQ > Celery > Flask > Flower protects core stateful services under node pressure.

---

### 5) Autoscaling & Backpressure

**Horizontal Pod Autoscaler (HPA):**
- **Celery Workers:** Scale 3→10 replicas based on CPU utilization (> 70%) or queue depth via KEDA RabbitMQ Scaler.
- **Flask API:** Optional CPU-based HPA for load spikes.

**Backpressure controls:**
- Celery's concurrency limit and `prefetch_multiplier` tuned to prevent overloading the database.
- Retry and dead-letter queues (DLQs) configured for failed jobs.

---

### 6) Networking & Ingress

**Internal Communication:**
- ClusterIP Services for RabbitMQ (amqp://), PostgreSQL (5432), Flask (5000), and Flower (5555).
- Kubernetes DNS names ensure service discovery.

**Ingress rules:**
- `/api` → Flask Service (Gunicorn)
- `/flower` → Flower Dashboard

**TLS:** Provided through self-signed cert-manager.

---

### Architecture Diagram

```
Kubernetes Workflow: Flask + RabbitMQ + Celery + PostgreSQL + Flower

External User
     |
     | HTTP(S) requests
     v
┌────────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (Namespace: workflow)                       │
│                                                                 │
│  Ingress Controller                                             │
│  (NGINX Ingress)                                                │
│  Routes: /api, /flower                                          │
│         |           |                                           │
│    /api route   /flower route                                   │
│         |           |                                           │
│  Flask API      Monitoring (Flower)                             │
│  (Producer)                                                     │
│         |                                                       │
│  Service: flask    Service: flower                              │
│  ClusterIP :5000   ClusterIP :5555                              │
│         |                |                                      │
│  Deployment: flask    Deployment: flower                        │
│  Image: asoucase/flask  Image: mher/flower                      │
│  Port :5000            Port :5555                               │
│         |                     |                                 │
│         |                     | Monitor broker queues           │
│         |                     | Monitor worker states           │
│         | AMQP publish task   |                                 │
│         v                     v                                 │
│    Message Broker                                               │
│                                                                 │
│    Service: rabbitmq                                            │
│    ClusterIP :5672 / :15672                                     │
│              |                                                  │
│    StatefulSet: rabbitmq                                        │
│    Image: rabbitmq:management                                   │
│    Ports :5672,15672                                            │
│              |                                                  │
│              | Queue data ←→ Deliver tasks via queue           │
│              v                              |                   │
│    PVC: rabbitmq-data                       v                   │
│    Persistent storage          Celery Workers (Consumers)       │
│                                             |                   │
│                                Deployment: celery-worker        │
│                                Image: asoucase/celery-worker    │
│                                Replicas: 3                      │
│                                             |                   │
│                                HPA: Scales 3 → 10               │
│                                Based on CPU or Queue Depth      │
│                                             |                   │
│                                             | Write results to Postgres
│                                             v                   │
│    Read results ←───────────────────── Database                │
│         |                                                       │
│         |                         Service: postgres             │
│         |                         ClusterIP :5432               │
│         |                                  |                    │
│         |                         StatefulSet: postgres         │
│         |                         Image: postgres:15            │
│         |                         Port :5432                    │
│         |                                  |                    │
│         |                                  | Persistent data    │
│         |                                  v                    │
│         |                         PVC: pgdata                   │
│         |                         PersistentVolumeClaim         │
│         |                                                       │
│         └─────────────────────────────────────────────────────┘
```

---

## Summary

This project demonstrates a production-ready microservices architecture on Kubernetes with:
- **Asynchronous task processing** using Celery and RabbitMQ
- **Persistent data storage** with PostgreSQL
- **Horizontal autoscaling** for dynamic workload management
- **Monitoring and visibility** through Flower dashboard
- **Proper resource management** with QoS classes and scheduling strategies
- **External access** via NGINX Ingress with TLS support
