# Fix Jenkins Cloud Build Integration

## Problem
Jenkins pipeline was only validating code but not actually triggering Cloud Build.

## Solution Steps

### 1. Build Custom Jenkins Image with Google Cloud SDK

```bash
# Build the custom Jenkins image
docker build -f jenkins-gcloud.Dockerfile -t gcr.io/alpine-beacon-473720-s5/jenkins-gcloud:latest .

# Push to Google Container Registry
docker push gcr.io/alpine-beacon-473720-s5/jenkins-gcloud:latest
```

### 2. Update Jenkins Deployment to Use Custom Image

Edit `jenkins-deployment.yaml` line 71 to use the custom image:

**Change from:**
```yaml
image: jenkins/jenkins:lts
```

**Change to:**
```yaml
image: gcr.io/alpine-beacon-473720-s5/jenkins-gcloud:latest
```

### 3. Create GCP Service Account Credentials

```bash
# Create service account for Jenkins
gcloud iam service-accounts create jenkins-cloudbuild \
    --display-name="Jenkins Cloud Build" \
    --project=alpine-beacon-473720-s5

# Grant necessary permissions
gcloud projects add-iam-policy-binding alpine-beacon-473720-s5 \
    --member="serviceAccount:jenkins-cloudbuild@alpine-beacon-473720-s5.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding alpine-beacon-473720-s5 \
    --member="serviceAccount:jenkins-cloudbuild@alpine-beacon-473720-s5.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding alpine-beacon-473720-s5 \
    --member="serviceAccount:jenkins-cloudbuild@alpine-beacon-473720-s5.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create jenkins-sa-key.json \
    --iam-account=jenkins-cloudbuild@alpine-beacon-473720-s5.iam.gserviceaccount.com
```

### 4. Create Kubernetes Secret with GCP Credentials

```bash
# Create secret in jenkins namespace
kubectl create secret generic gcp-credentials \
    --from-file=key.json=jenkins-sa-key.json \
    -n jenkins

# Clean up local key file (security best practice)
rm jenkins-sa-key.json
```

### 5. Mount GCP Credentials in Jenkins Pod

Add to jenkins-deployment.yaml under `spec.template.spec.containers[0]`:

```yaml
        env:
        - name: JENKINS_OPTS
          value: "--httpPort=8080"
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=true"
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /var/secrets/google/key.json
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: jenkins-init-script
          mountPath: /usr/share/jenkins/ref/init.groovy.d/
        - name: gcp-credentials
          mountPath: /var/secrets/google
          readOnly: true
```

And add under `spec.template.spec.volumes`:

```yaml
      - name: gcp-credentials
        secret:
          secretName: gcp-credentials
```

### 6. Apply Updated Deployment

```bash
# Apply the updated deployment
kubectl apply -f jenkins-deployment.yaml

# Wait for pod to restart
kubectl rollout status deployment/jenkins -n jenkins

# Check pod is running
kubectl get pods -n jenkins
```

### 7. Configure gcloud in Jenkins

Once Jenkins restarts, run these commands inside the Jenkins pod:

```bash
# Get Jenkins pod name
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

# Exec into pod and configure gcloud
kubectl exec -it $JENKINS_POD -n jenkins -- bash

# Inside the pod:
gcloud auth activate-service-account --key-file=/var/secrets/google/key.json
gcloud config set project alpine-beacon-473720-s5
exit
```

### 8. Test the Pipeline

Push a change to your GitHub repository and verify:
- Jenkins automatically triggers
- Cloud Build is executed (not just echoed)
- New image is built and pushed to GCR
- Deployment is updated in GKE

## Verification

Check Cloud Build history:
```bash
gcloud builds list --project=alpine-beacon-473720-s5 --limit=5
```

Check Jenkins logs:
```bash
# View Jenkins pod logs
kubectl logs -f deployment/jenkins -n jenkins
```

## What Changed

1. **Jenkinsfile** now actually runs `gcloud builds submit` instead of just echoing instructions
2. **Jenkins image** includes Google Cloud SDK and kubectl
3. **GCP authentication** is configured via service account
4. **Deployment verification** actually checks rollout status using kubectl

