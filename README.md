# Voting App - ArgoCD Multi-Cluster Deployment with Helm

This directory contains a Helm chart that implements a simplified multi-cluster deployment pattern for the voting application using ArgoCD. The Helm chart creates individual ArgoCD `Application` resources for each service component, with environment-specific configurations.

## Architecture

The simplified multi-cluster deployment pattern consists of:

1. **Helm Chart**: A chart that contains templates for ArgoCD `Application` resources.
2. **Individual Applications**: Each component of the voting app has its own ArgoCD Application:
   - `database-app` - PostgreSQL database
   - `redis-app` - Redis cache
   - `vote-app` - Vote frontend service
   - `result-app` - Result display service
   - `worker-app` - Background worker
3. **Kubernetes Manifests**: Standard Kubernetes manifests (`Deployment`, `Service`, etc.) for each application component, stored in a separate directory.
4. **Environment-Specific Configuration**: Separate values files for different environments (dev, prod) with cluster-specific settings.

## Directory Structure

```
.
├── Chart.yaml                    # Helm chart metadata
├── values-dev.yaml               # Development environment values
├── values-prod.yaml              # Production environment values
├── templates/                    # Helm templates for ArgoCD Applications
│   ├── _helpers.tpl
│   └── applications.yaml
├── k8s-manifests/                # Kubernetes manifests for each service
│   ├── database/
│   ├── redis/
│   ├── vote/
│   ├── result/
│   └── worker/
└── README.md                     # This file
```

## Features

### 🔧 Configurable Values
- **Environment-specific settings**: Different configurations for dev, staging, prod
- **Component toggles**: Enable/disable individual applications
- **Cluster targeting**: Direct cluster specification per environment
- **Sync policies**: Configurable sync behavior per environment

### 🏷️ Helm Labels
- Standard Helm labels for all resources
- Environment and component-specific labels for easy filtering
- Release tracking and version management

### 🌍 Multi-Environment Support
- Development environment targeting in-cluster
- Production environment targeting remote cluster (cluster-68)
- Easy to add staging or other environments

## Deployment

### Prerequisites

1. ArgoCD installed in your management cluster
2. Helm 3.x installed
3. Access to the Git repository where this code is hosted
4. Target clusters registered in ArgoCD

### Steps

1. **Commit and Push Your Changes**:
   ArgoCD uses Git as the source of truth. Before deploying or upgrading, ensure all your changes (e.g., modifications to the `k8s-manifests`) are committed and pushed to your repository.
   ```bash
   git add .
   git commit -m "Your descriptive commit message"
   git push
   ```

2. **Deploy a New Environment**:
   To deploy a new instance of the application stack (e.g., for production), run `helm install`. This command creates the ArgoCD `Application` resources in the management cluster. ArgoCD will then detect these resources and deploy the manifests from the specified path in your Git repository.
   ```bash
   # For Development (in-cluster)
   helm install voting-app-dev . --values ./values-dev.yaml --namespace voting-app-dev

   # For Production (cluster-68)
   helm install voting-app-prod . --values ./values-prod.yaml --namespace voting-app-prod
   ```

3. **Upgrade an Existing Deployment**:
   If you've made changes to the Helm chart itself or need to point to a new Git revision, use `helm upgrade`.
   ```bash
   helm upgrade voting-app-prod . --values ./values-prod.yaml
   ```

## Configuration

### Values Structure

The values files configure individual ArgoCD `Application` resources. Each application has its own configuration block with source, destination, and sync policy settings.

```yaml
applications:
  database:
    enabled: true
    name: database-app-prod
    component: database
    environment: prod
    project: default
    source:
      repoURL: https://github.com/CHARANPRAJWAL/ArgoCD-Multicluster-Deployments.git
      targetRevision: main
      path: k8s-manifests/database
    destination:
      server: https://10.201.1.105:6443
      namespace: voting-app-prod
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
        - PrunePropagationPolicy=foreground
        - PruneLast=true
```

### Environment-Specific Values

#### Development (`values-dev.yaml`)
- Uses `develop` branch
- Targets in-cluster (`https://kubernetes.default.svc`)
- Deploys to `voting-app-dev` namespace
- Application names are suffixed with `-dev`

#### Production (`values-prod.yaml`)
- Uses `main` branch
- Targets cluster-68 (`https://10.201.1.105:6443`)
- Deploys to `voting-app-prod` namespace
- Application names are suffixed with `-prod`

## Benefits of Simplified Multi-Cluster Deployment

- **Direct Control**: Each application is managed independently
- **Environment Management**: Clear separation between environments
- **Version Control**: Use Helm release tracking and rollback for the ArgoCD Application setup
- **Reusability**: Use the same chart to stamp out multiple, isolated environments
- **Simplicity**: No complex parent-child relationships to manage
- **Scalability**: Easy to add new environments or components

## Monitoring

### Helm Commands

Use Helm to manage the lifecycle of the ArgoCD `Application` resources.

```bash
# List Helm releases (shows your dev and prod setups)
helm list

# Get status of a release
helm status voting-app-dev
```

### ArgoCD Commands

Use the ArgoCD CLI to check the status of the applications and their resources.

```bash
# List all applications managed by ArgoCD
argocd app list

# Get the status of an application
argocd app get database-app-prod

# Sync an application manually (if not automated)
argocd app sync database-app-prod
```

## Troubleshooting

### Common Issues

1. **ArgoCD shows `Missing` or `OutOfSync` status**:
   - This is often a caching issue after a `git push`. Wait a few moments and click the `Refresh` button in the ArgoCD UI for the application.
   - Verify the `repoURL` and `targetRevision` in your values file are correct.

2. **Application sync failed**:
   - Check the ArgoCD application logs for detailed error messages: `argocd app logs database-app-prod`
   - Ensure the manifests in the `k8s-manifests` directory are valid Kubernetes YAML.

3. **Helm installation failed**:
   - Run `helm lint .` to check for chart syntax issues.
   - Verify all required values are set in your `values-*.yaml` file.

### Debug Commands

```bash
# Lint the chart for syntax errors
helm lint .

# Perform a dry run of an installation to see the generated ArgoCD manifests
helm install --dry-run --debug voting-app-dev . --values ./values-dev.yaml

# Render templates locally to inspect the output
helm template voting-app-dev . --values ./values-dev.yaml
```

## Cluster Configuration

### Target Clusters

- **Development**: `https://kubernetes.default.svc` (in-cluster)
- **Production**: `https://10.201.1.105:6443` (cluster-68)

### RBAC Setup

Ensure proper RBAC is configured for ArgoCD to manage resources in target namespaces:

```bash
# Apply RBAC for dev environment
kubectl apply -f k8s-manifests/dev/argocd-rbac.yaml

# Apply RBAC for prod environment (use appropriate context)
kubectl --context=<prod-context> apply -f k8s-manifests/prod/argocd-rbac.yaml
```

## About

This simplified approach provides a clean, maintainable solution for multi-cluster deployments without the complexity of the App of Apps pattern, while maintaining full GitOps compliance and environment isolation. 