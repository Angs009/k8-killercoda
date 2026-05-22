# k8-killercoda

Kubernetes manifests for Killercoda.

## Files

| File | Purpose |
|------|---------|
| `ns.yml` | Namespace `prod-ns` |
| `pod.yaml` | Single-container pod |
| `multi-pod.yaml` | Multi-container pod (`exe-pod`) |

## Killercoda

```bash
git clone https://github.com/Angs009/k8-killercoda.git
cd k8-killercoda
kubectl apply -f ns.yml
kubectl apply -f multi-pod.yaml
kubectl get pods
kubectl describe pod exe-pod
```

## Use your own container

Edit `multi-pod.yaml` under `spec.containers` — change `name`, `image`, and `containerPort` to match your Docker Hub image.
