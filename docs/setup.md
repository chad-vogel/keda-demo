# Environment Setup

This walkthrough creates a self-contained Kubernetes environment using [Podman](https://podman.io/) and [kind](https://kind.sigs.k8s.io/) on macOS. The same ideas apply if you prefer Docker Desktop, Rancher Desktop, or managed services such as Azure Kubernetes Service (AKS), Amazon Elastic Kubernetes Service (EKS), or Google Kubernetes Engine (GKE)—we call out alternatives at the end.

> **Audience:** Engineers comfortable with the command line but new to Kubernetes operations. Each step includes a quick explanation so you know *why* you are running the command.

## 1. Prepare Podman (container runtime)

Podman provides the container engine that builds and runs our demo images.

```bash
podman machine init   # First-time setup: provision the Podman virtual machine (VM)
podman machine start  # Boot the VM
podman info           # Verify the VM is responding
```

Many Kubernetes tools (including kind) look for a Docker-compatible socket. Podman can expose one for compatibility:

```bash
podman machine set --rootful          # Allow privileged socket forwarding
podman machine start                  # Restart the VM if it was running
podman machine ssh -- \
  systemctl --user enable --now podman.socket
export DOCKER_HOST="unix://${HOME}/.local/share/containers/podman/machine/podman.sock"
```

Add the `export DOCKER_HOST=…` line to your shell profile (`~/.zshrc`, `~/.bashrc`, etc.) so new shells automatically pick it up.

## 2. Install kind (lightweight Kubernetes)

kind (“Kubernetes in Docker/Podman”) spins up a single-node cluster inside the container runtime.

```bash
# Apple silicon (arm64)
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-darwin-arm64

# Intel (amd64)
# curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-darwin-amd64

chmod +x kind
mv kind /usr/local/bin/           # Optional: place on the PATH environment variable, or keep it in the repo
kind version                      # Verify the binary works
```

If you cannot modify `/usr/local/bin`, leave the binary in the repo and run it as `./kind`.

## 3. Create a Cluster

Tell kind to use Podman as the backing runtime and create a new cluster named `keda-demo`:

```bash
KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name keda-demo
kubectl config use-context kind-keda-demo
```

- `KIND_EXPERIMENTAL_PROVIDER=podman` switches kind from Docker to Podman.
- `kubectl config use-context …` ensures subsequent `kubectl` commands talk to the new cluster.

Confirm the cluster is healthy:

```bash
kubectl get nodes
kubectl get ns
```

You should see one node (the control plane) and the default system namespaces.

## 4. Load Local Images (optional but recommended)

The demo images are tagged as `localhost/...`. Load them into the kind node after you build them so Kubernetes can run the workloads without reaching out to an external registry.

```bash
podman save -o /tmp/keda-images.tar \
  localhost/keda-cpu-api:dev \
  localhost/keda-queue-worker:dev \
  localhost/keda-queue-producer:dev

KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive --name keda-demo /tmp/keda-images.tar
```

If you push the images to a remote registry instead, skip this step and update the manifests or environment variables to reference your registry paths.

## 5. Validate Tooling

Sanity check that the main tools respond:

```bash
kind get clusters                   # Should list keda-demo
kubectl version --client            # Prints kubectl client info
podman images | grep keda           # Shows the demo images you built
```

You are now ready to follow the [demo overview](overview.md).

## Alternatives & Tips

- **Docker Desktop / Rancher Desktop** – Enable the built-in Kubernetes cluster. Use `docker load` or `nerdctl load` to preload images.
- **Minikube** – Run `minikube start`, then use `minikube image build` or enable the registry addon to host your images.
- **Managed clusters (AKS/EKS/GKE)** – Authenticate with `kubectl`, push images to an accessible registry (ACR/ECR/GCR/etc.), and update the manifests or environment variables with the remote image names.

Regardless of platform, make sure the cluster:

- Runs Kubernetes v1.24 or newer (v1.30 verified).
- Has enough capacity for a few small deployments (2 virtual CPUs, vCPU / 4 gibibytes of memory, GiB, is plenty).
- Allows access to the aggregated `external.metrics.k8s.io` Application Programming Interface Service (APIService) that KEDA registers (no restrictive firewalls or admission policies blocking it).
