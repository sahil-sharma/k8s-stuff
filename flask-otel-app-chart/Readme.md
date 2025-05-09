# Flask CRUD App Helm Chart

This Helm chart deploys a simple Flask-based CRUD application to a Kubernetes cluster. It includes resources such as Deployment, Service, Ingress, ConfigMap, Secret, HPA, PDB, and ServiceAccount.

## Features

- Configurable Flask container image
- Horizontal Pod Autoscaling (HPA)
- Ingress with multiple paths
- Liveness and readiness probes
- PodDisruptionBudget support
- Resource limits and requests
- ServiceAccount for RBAC

## Installation

1. **Clone the repo:**

```bash
helm upgrade --install my-app ./flask-otel-app-chart -namespace my-app --create-namespace
```