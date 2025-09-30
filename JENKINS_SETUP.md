# Jenkins CI/CD Setup Guide

## Jenkins Deployment Information

### Access Information
- **Jenkins URL**: http://34.133.54.193
- **Admin User**: admin (default)
- **Setup**: Wizard disabled, manual configuration required

### Kubernetes Resources
- **Namespace**: jenkins
- **Service**: jenkins-service (LoadBalancer)
- **Storage**: 20Gi persistent volume
- **Resources**: 512Mi RAM, 250m CPU (request), 1Gi RAM, 500m CPU (limit)

## GitHub Integration Setup

### Step 1: Initial Jenkins Configuration

1. **Access Jenkins**: Open http://34.133.54.193 in your browser

2. **Create Admin User** (if setup wizard appears):
   - Username: admin
   - Password: admin123 (or your preferred password)
   - Full Name: Jenkins Admin
   - Email: admin@example.com

3. **Install Required Plugins**:
   - Navigate to "Manage Jenkins" → "Manage Plugins"
   - Install these plugins:
     - GitHub plugin
     - GitHub Branch Source plugin
     - Pipeline plugin
     - Docker plugin
     - Google Kubernetes Engine plugin
     - Blue Ocean (optional, for better UI)

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

1. **Create Service Account Key**:
   ```bash
   # Create service account
   gcloud iam service-accounts create jenkins-ci --description="Jenkins CI/CD" --display-name="Jenkins CI"
   
   # Grant necessary permissions
   gcloud projects add-iam-policy-binding alpine-beacon-473720-s5 \
     --member="serviceAccount:jenkins-ci@alpine-beacon-473720-s5.iam.gserviceaccount.com" \
     --role="roles/container.developer"
   
   gcloud projects add-iam-policy-binding alpine-beacon-473720-s5 \
     --member="serviceAccount:jenkins-ci@alpine-beacon-473720-s5.iam.gserviceaccount.com" \
     --role="roles/storage.admin"
   
   # Create and download key
   gcloud iam service-accounts keys create jenkins-key.json \
     --iam-account=jenkins-ci@alpine-beacon-473720-s5.iam.gserviceaccount.com
   ```

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

2. **GCP Authentication Issues**:
   - Verify service account has correct permissions
   - Check credentials are properly uploaded
   - Ensure gcloud is configured in Jenkins container

3. **Docker Build Failures**:
   - Check Docker daemon is accessible
   - Verify Dockerfile syntax
   - Check available disk space

4. **Kubernetes Deployment Issues**:
   - Verify kubectl can connect to cluster
   - Check namespace exists
   - Verify image name and tag are correct

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

## Pipeline Flow

```
GitHub Push → Webhook → Jenkins → Build Docker Image → Push to GCR → Deploy to GKE → Health Check
```

The complete CI/CD pipeline ensures:
- ✅ Automated builds on code changes
- ✅ Container image versioning
- ✅ Zero-downtime deployments
- ✅ Automated health checks
- ✅ Scalable infrastructure (3 pods minimum)