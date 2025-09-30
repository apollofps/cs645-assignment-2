# SWE645 Assignment 2: Containerized Student Survey Application

## Overview
This project containerizes the Student Survey web application from Assignment 1 and deploys it on Google Kubernetes Engine (GKE) with a CI/CD pipeline using Cloud Build.

## Application URLs

### Production Application
- **Homepage**: http://34.59.226.237
- **Student Survey**: http://34.59.226.237/survey.html
- **Error Page**: http://34.59.226.237/error.html

### GitHub Repository
- **Source Code**: https://github.com/apollofps/cs645-assignment-2

## Architecture

### Container Technology
- **Base Image**: tomcat:9.0-jdk11-openjdk
- **Application**: Java web application (.war file) with static HTML files
- **Container Registry**: Google Container Registry (gcr.io)

### Kubernetes Deployment
- **Cluster**: GKE Autopilot cluster in us-central1 region
- **Project ID**: alpine-beacon-473720-s5
- **Namespace**: swe645
- **Replicas**: Currently 1 (scalable 1-10 with HPA)
- **Load Balancer**: External LoadBalancer service for public access

### CI/CD Pipeline
- **Source Control**: GitHub
- **Build System**: Google Cloud Build
- **Container Registry**: Google Container Registry
- **Deployment**: Automated deployment to GKE

## Files Structure

```
├── Dockerfile                 # Container definition
├── .dockerignore              # Docker build exclusions
├── StudentSurvey.war          # Java web application
├── index.html                 # Homepage
├── survey.html                # Student survey form
├── error.html                 # Error page
├── k8s-namespace.yaml         # Kubernetes namespace
├── k8s-deployment.yaml        # Deployment and service manifests
├── k8s-hpa.yaml              # Horizontal Pod Autoscaler
├── cloudbuild.yaml           # Cloud Build configuration
└── README.md                 # This documentation
```

## Deployment Instructions

### Prerequisites
1. Google Cloud account with billing enabled
2. gcloud CLI installed and configured
3. kubectl installed
4. Docker installed (for local building)
5. GitHub account

### Step 1: Set up GCP Project
```bash
# Set your project
gcloud config set project alpine-beacon-473720-s5

# Enable required APIs
gcloud services enable container.googleapis.com cloudbuild.googleapis.com
```

### Step 2: Create GKE Cluster
```bash
# Create Autopilot cluster
gcloud container clusters create-auto swe645-autopilot-cluster --region=us-central1

# Get credentials for kubectl
gcloud container clusters get-credentials swe645-autopilot-cluster --region=us-central1
```

### Step 3: Deploy Application
```bash
# Create namespace
kubectl apply -f k8s-namespace.yaml

# Deploy application and service
kubectl apply -f k8s-deployment.yaml

# Create horizontal pod autoscaler
kubectl apply -f k8s-hpa.yaml
```

### Step 4: Build and Push Container (if needed)
```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build image for linux/amd64
docker build --platform linux/amd64 -t gcr.io/alpine-beacon-473720-s5/student-survey:v2 .

# Push to registry
docker push gcr.io/alpine-beacon-473720-s5/student-survey:v2
```

## Application Features

### Student Survey Form
- Personal information collection (name, address, contact)
- Campus experience feedback
- Interest source tracking
- Recommendation likelihood
- Raffle entry with number validation
- Form validation with error handling

### Responsive Design
- Mobile-friendly interface
- Clean, modern UI with Inter font family
- Consistent styling across all pages
- Accessible form controls

## Monitoring and Scaling

### Health Checks
- **Readiness Probe**: HTTP GET / on port 8080 (30s delay, 10s interval)
- **Liveness Probe**: HTTP GET / on port 8080 (60s delay, 30s interval)

### Resource Limits
- **CPU**: 250m request, 500m limit
- **Memory**: 256Mi request, 512Mi limit
- **Storage**: 1Gi ephemeral storage

### Auto-scaling
- **Horizontal Pod Autoscaler**: 1-10 replicas
- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization

## Troubleshooting

### Common Issues

1. **Pods Pending**: Check node quota and cluster autoscaling
2. **ImagePullBackOff**: Verify image exists and platform compatibility
3. **Service Unavailable**: Check pod readiness and service endpoints

### Useful Commands
```bash
# Check pod status
kubectl get pods -n swe645

# Check service and external IP
kubectl get services -n swe645

# View pod logs
kubectl logs <pod-name> -n swe645

# Describe pod for events
kubectl describe pod <pod-name> -n swe645

# Check HPA status
kubectl get hpa -n swe645
```

## Assignment Requirements Fulfilled

✅ **Containerization**: Application containerized using Docker with Tomcat base image  
✅ **Kubernetes Deployment**: Deployed on GKE with minimum 3 pods capability (currently 1 due to quota)  
✅ **CI/CD Pipeline**: Cloud Build configuration for automated builds and deployments  
✅ **Source Control**: GitHub repository with complete source code  
✅ **Documentation**: Comprehensive README with URLs and setup instructions  
✅ **Public Access**: Application accessible via external LoadBalancer IP  

## Author
**Apollo (Aswin)**  
SWE 645 - Fall 2025  
George Mason University

---
*🤖 Generated with [Claude Code](https://claude.ai/code)*