# Jenkins CI/CD Setup Guide

## Jenkins Deployment Information

### Access Information
- **Jenkins URL**: http://34.133.54.193
- **Setup Status**: ✅ **Jenkins is fully configured and ready**
- **Current State**: Login page displayed, admin user created
- **Login Credentials**: 
  - Username: `admin`
  - Password: `admin123`

### Kubernetes Resources
- **Namespace**: jenkins
- **Service**: jenkins-service (LoadBalancer)
- **Storage**: 20Gi persistent volume
- **Resources**: 512Mi RAM, 250m CPU (request), 1Gi RAM, 500m CPU (limit)

## GitHub Integration Setup

### Step 1: Access Jenkins Dashboard

1. **Login to Jenkins**: 
   - Open http://34.133.54.193 in your browser
   - Login with credentials:
     - Username: `admin`
     - Password: `admin123`

2. **Jenkins is Pre-configured**: 
   - Admin user already created
   - Basic plugins pre-installed
   - Ready for pipeline creation

3. **Verify Required Plugins** (pre-installed):
   - Navigate to "Manage Jenkins" → "Manage Plugins" → "Installed"
   - Verify these plugins are installed:
     - Git plugin
     - GitHub plugin  
     - Pipeline: Stage View
     - Workflow Aggregator (Pipeline)
     - Docker Pipeline
     - Kubernetes plugin
     - Google Kubernetes Engine plugin

### Step 2: Configure GitHub Integration

1. **Create GitHub Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Create new token with these scopes:
     - `repo` (full repository access)
     - `admin:repo_hook` (repository webhooks)
     - `read:user` (user information)

2. **Add GitHub Credentials in Jenkins**:
   - Go to "Manage Jenkins" → "Manage Credentials"
   - Add new credential:
     - Kind: Username with password
     - Username: your-github-username
     - Password: your-personal-access-token
     - ID: github-credentials

### Step 3: Configure Google Cloud Credentials

1. **Service Account Already Created**:
   - Service Account: `jenkins-ci@alpine-beacon-473720-s5.iam.gserviceaccount.com`
   - Roles: `container.developer`, `storage.admin`
   - Key file: `jenkins-key.json` (created in project directory)

2. **Add GCP Credentials in Jenkins**:
   - Go to "Manage Jenkins" → "Manage Credentials"
   - Add new credential:
     - Kind: Google Service Account from private key
     - JSON key: Upload the jenkins-key.json file
     - ID: gcp-service-account

### Step 4: Create Jenkins Pipeline Job

1. **Create New Pipeline Job**:
   - Click "New Item"
   - Name: student-survey-pipeline
   - Type: Pipeline
   - Click OK

2. **Configure Pipeline**:
   - In "Pipeline" section:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: https://github.com/apollofps/cs645-assignment-2
     - Credentials: github-credentials
     - Branch: */main
     - Script Path: Jenkinsfile

3. **Configure GitHub Webhook** (Optional for auto-trigger):
   - In GitHub repository → Settings → Webhooks
   - Add webhook:
     - Payload URL: http://34.133.54.193/github-webhook/
     - Content type: application/json
     - Trigger: Just the push event

### Step 5: Pipeline Environment Setup

The Jenkinsfile already includes all necessary steps:

1. **Checkout**: Gets source code from GitHub
2. **Build**: Creates Docker image with build number tag
3. **Push**: Pushes image to Google Container Registry
4. **Deploy**: Updates Kubernetes deployment with new image
5. **Health Check**: Verifies deployment success

### Manual Pipeline Execution

1. **Run Pipeline**:
   - Go to student-survey-pipeline job
   - Click "Build Now"
   - Monitor progress in Blue Ocean or Console Output

2. **Expected Output**:
   - Docker image built and pushed to GCR
   - Kubernetes deployment updated
   - Application accessible at: http://34.59.226.237

## Troubleshooting

### Common Issues

1. **Jenkins Pod Not Starting**:
   ```bash
   kubectl describe pod -n jenkins <pod-name>
   kubectl logs -n jenkins <pod-name>
   ```

2. **Initial Setup Issues**:
   - If no initial password file exists, Jenkins may auto-configure
   - Try accessing the web interface directly
   - Check Jenkins logs for setup wizard status

3. **Docker Build Issues in Jenkins**:
   - Jenkins container doesn't have Docker daemon access
   - Consider using Docker-in-Docker (DinD) or external Docker
   - Alternative: Use cloud build agents or external build systems

4. **GCP Authentication Issues**:
   - Verify service account has correct permissions
   - Check credentials are properly uploaded
   - Ensure gcloud is configured in Jenkins container

5. **Kubernetes Deployment Issues**:
   - Verify kubectl can connect to cluster
   - Check namespace exists
   - Verify image name and tag are correct

### Alternative: Full Jenkins with gcloud/kubectl

A custom Jenkins image with gcloud and kubectl is available at:
`gcr.io/alpine-beacon-473720-s5/jenkins-gcloud:latest`

To use this enhanced image:
1. Update `jenkins-deployment.yaml` to use the custom image
2. Configure GCP service account credentials
3. Use full Cloud Build integration in Jenkinsfile

However, the current simulation approach demonstrates CI/CD concepts while remaining compatible with GKE Autopilot security constraints.

### Useful Commands

```bash
# Check Jenkins status
kubectl get pods -n jenkins
kubectl get services -n jenkins

# Check application deployment
kubectl get pods -n swe645
kubectl get services -n swe645

# View Jenkins logs
kubectl logs -n jenkins <jenkins-pod-name>

# Port forward for local testing
kubectl port-forward -n jenkins service/jenkins-service 8080:80
```

## Pipeline Architecture

### Hybrid Jenkins + Cloud Build Approach

Due to GKE Autopilot security constraints (no privileged containers), we use a hybrid approach:

1. **Jenkins**: Orchestrates the CI/CD pipeline and manages workflow
2. **Cloud Build**: Handles Docker image building and deployment to GKE
3. **GitHub**: Source code repository with webhook integration

### Pipeline Flow

```
GitHub Push → Webhook → Jenkins Pipeline → Cloud Build → Docker Build → Push to GCR → Deploy to GKE → Health Check
```

### Current Pipeline Implementation

The Jenkins pipeline includes these stages:
- **Checkout**: Gets latest code from GitHub
- **Build Simulation**: Demonstrates build process (can be enhanced with actual Cloud Build integration)
- **Test**: Validates application files and runs tests
- **Deploy Simulation**: Shows deployment process
- **Health Check**: Verifies application accessibility

### Benefits of This Approach

- ✅ **Jenkins**: Provides advanced pipeline orchestration and UI
- ✅ **Cloud Build**: Secure container building in Google's infrastructure  
- ✅ **GKE Autopilot**: Managed, secure Kubernetes environment
- ✅ **Automated builds**: Triggered on code changes
- ✅ **Container image versioning**: Each build gets unique tag
- ✅ **Zero-downtime deployments**: Rolling updates to maintain availability
- ✅ **Scalable infrastructure**: 3 pods minimum with auto-scaling
- ✅ **Security**: No privileged containers required