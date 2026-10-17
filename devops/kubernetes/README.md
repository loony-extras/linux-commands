# Kubernetes

Deployments, services and policies.

---

## Files

- [deployment.yml](deployment.yml)
- [namespace.yml](namespace.yml)
- [service.yml](service.yml)

---

## Usage

```bash
cd devops/kubernetes/
kubectl apply -f .                                   # namespace, deployment, service
kubectl rollout status deployment/myapp -n myapp
kubectl scale deployment myapp --replicas=5 -n myapp
kubectl get events -n myapp --sort-by='.lastTimestamp'
```

The manifests include:
- **Deployment**: rolling update, topology spread, non-root, readOnlyRootFilesystem, drop ALL capabilities
- **HPA**: autoscale 2–10 replicas on CPU 70% / memory 80%
- **PDB**: minimum 2 replicas available during node maintenance
- **NetworkPolicy**: deny all except ingress controller → app and app → postgres/redis/DNS/HTTPS
- **Ingress**: TLS via cert-manager, nginx rate limiting

---

## Kubernetes Basics

The manifests are in this folder (see Files above).

```bash
# kubectl essentials
kubectl get nodes
kubectl get pods -n myapp
kubectl get pods --all-namespaces
kubectl describe pod mypod -n myapp
kubectl logs mypod -n myapp
kubectl logs -f mypod -n myapp -c mycontainer
kubectl exec -it mypod -n myapp -- bash

# Apply manifests
kubectl apply -f deployment.yml
kubectl apply -f kubernetes/         # Apply entire directory

# Rollout management
kubectl rollout status deployment/myapp -n myapp
kubectl rollout history deployment/myapp -n myapp
kubectl rollout undo deployment/myapp -n myapp  # Rollback

# Scaling
kubectl scale deployment myapp --replicas=5 -n myapp
kubectl autoscale deployment myapp --min=2 --max=10 --cpu-percent=70 -n myapp

# Resource inspection
kubectl top nodes
kubectl top pods -n myapp
kubectl get events -n myapp --sort-by='.lastTimestamp'
```

