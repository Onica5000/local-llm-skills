---
name: containers-k8s
description: Use for Docker and Kubernetes work â€” building/running/managing containers (docker, docker-compose) and managing clusters (kubectl). Also covers QEMU VMs and WSL for Linux.
---

# containers-k8s

docker 29.5, docker-compose, kubectl v1.34 installed.

## Docker
```powershell
docker ps                 # running containers (-a for all)
docker images
docker build -t myimage .
docker run --rm -it -p 8080:80 myimage
docker run --rm -v "${PWD}:/work" -w /work <image> <cmd>   # mount cwd (note ${PWD} in PS)
docker exec -it <container> sh
docker logs -f <container>
docker stop <container>; docker rm <container>
docker system prune        # reclaim space (asks to confirm)
```

## docker-compose
```powershell
docker compose up -d        # start stack detached
docker compose ps
docker compose logs -f
docker compose down         # stop & remove
```

## kubectl
```powershell
kubectl config current-context
kubectl get pods -A
kubectl get svc,deploy
kubectl describe pod <name>
kubectl logs -f <pod>
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
```

## Related on this machine
- **QEMU** (`qemu-system-x86_64`, `-aarch64`, `-riscv64`, `qemu-img`) for full VMs.
- **WSL** (`wsl`) to run Linux tools without a VM, e.g. `wsl ls -la /mnt/c/Users`.

## Rules
- In PowerShell use `${PWD}` (not `$(pwd)`) for the current dir in `-v` mounts.
- `prune`/`delete`/`down` remove things â€” confirm with the user before destructive cleanup.

