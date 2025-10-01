#!/bin/bash

# Setup script to configure Jenkins to trigger Cloud Build
# This script automates the steps needed to integrate Jenkins with GCP Cloud Build

set -e  # Exit on error

PROJECT_ID="alpine-beacon-473720-s5"
SERVICE_ACCOUNT_NAME="jenkins-cloudbuild"
SA_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🚀 Setting up Jenkins Cloud Build Integration"
echo "================================================"
echo ""

# Step 1: Build and push custom Jenkins image
echo "📦 Step 1: Building custom Jenkins image with Google Cloud SDK..."
docker build -f jenkins-gcloud.Dockerfile -t gcr.io/${PROJECT_ID}/jenkins-gcloud:latest .

echo "📤 Pushing image to Google Container Registry..."
docker push gcr.io/${PROJECT_ID}/jenkins-gcloud:latest

echo "✅ Custom Jenkins image ready!"
echo ""

# Step 2: Create service account
echo "🔐 Step 2: Creating GCP Service Account..."
if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
    echo "Service account already exists, skipping creation..."
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="Jenkins Cloud Build" \
        --project=$PROJECT_ID
    echo "✅ Service account created!"
fi
echo ""

# Step 3: Grant permissions
echo "🔑 Step 3: Granting IAM permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/cloudbuild.builds.editor" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/container.developer" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin" \
    --quiet

echo "✅ Permissions granted!"
echo ""

# Step 4: Create service account key
echo "🔑 Step 4: Creating service account key..."
gcloud iam service-accounts keys create jenkins-sa-key.json \
    --iam-account=$SA_EMAIL

echo "✅ Key created!"
echo ""

# Step 5: Create Kubernetes secret
echo "🔐 Step 5: Creating Kubernetes secret..."
kubectl create secret generic gcp-credentials \
    --from-file=key.json=jenkins-sa-key.json \
    -n jenkins \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret created!"
echo ""

# Step 6: Clean up local key file
echo "🧹 Cleaning up local key file..."
rm -f jenkins-sa-key.json
echo "✅ Cleaned up!"
echo ""

# Step 7: Apply updated Jenkins deployment
echo "🚀 Step 6: Deploying updated Jenkins configuration..."
kubectl apply -f jenkins-deployment.yaml

echo "⏳ Waiting for Jenkins to restart..."
kubectl rollout status deployment/jenkins -n jenkins --timeout=5m

echo "✅ Jenkins deployment updated!"
echo ""

# Step 8: Configure gcloud in Jenkins pod
echo "⚙️  Step 7: Configuring gcloud in Jenkins pod..."
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

kubectl exec $JENKINS_POD -n jenkins -- bash -c "
    gcloud auth activate-service-account --key-file=/var/secrets/google/key.json
    gcloud config set project $PROJECT_ID
    echo 'gcloud authentication configured successfully'
"

echo "✅ gcloud configured in Jenkins!"
echo ""

echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "📋 Next steps:"
echo "1. Push a change to your GitHub repository"
echo "2. Jenkins will automatically trigger"
echo "3. Cloud Build will be executed (not just echoed)"
echo "4. Check Cloud Build console: https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
echo ""
echo "🔍 To verify Cloud Build is working:"
echo "   gcloud builds list --project=$PROJECT_ID --limit=5"
echo ""
echo "📝 To check Jenkins logs:"
echo "   kubectl logs -f deployment/jenkins -n jenkins"
echo ""

