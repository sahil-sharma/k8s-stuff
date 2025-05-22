# Flask App Helm Chart

This Helm chart deploys a simple Flask-based CRUD application to a Kubernetes cluster. It includes resources such as Deployment, Service, Ingress, ConfigMap, Secret, HPA, PDB, and ServiceAccount.

## Features

- Configurable Flask container image
- Horizontal Pod Autoscaling (HPA)
- Ingress with multiple paths
- Liveness and readiness probes
- PodDisruptionBudget support
- Resource limits and requests
- ServiceAccount for RBAC

## Code for the Application

You can read the code for the application [here](https://github.com/sahil-sharma/flask-otel-app/)

## Installation

1. **Install the Helm Chart:**

```bash
helm upgrade --install flask-app ./flask-otel-app-chart -namespace flask-app --create-namespace
```