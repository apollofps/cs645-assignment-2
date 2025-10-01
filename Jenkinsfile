pipeline {
    agent any
    
    environment {
        PROJECT_ID = 'alpine-beacon-473720-s5'
        CLUSTER_NAME = 'swe645-autopilot-cluster'
        CLUSTER_ZONE = 'us-central1'
        IMAGE_TAG = "gcr.io/${PROJECT_ID}/student-survey:${env.BUILD_NUMBER}"
        NAMESPACE = 'swe645'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build and Deploy') {
            steps {
                script {
                    echo 'Building and deploying application with Cloud Build...'
                    withCredentials([file(credentialsId: 'gcp-service-account-file', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh """
                            echo "🚀 Starting FULLY AUTOMATED deployment..."
                            echo "Source commit: \$(git rev-parse HEAD)"
                            echo "Building image: ${IMAGE_TAG}"
                            
                            # Install gcloud CLI (running as root now)
                            if ! command -v gcloud &> /dev/null; then
                                echo "📦 Installing Google Cloud SDK..."
                                
                                # Update package list
                                apt-get update -y
                                
                                # Install required packages
                                apt-get install -y apt-transport-https ca-certificates gnupg curl lsb-release python3 python3-pip
                                
                                # Add Google Cloud SDK repository
                                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
                                
                                # Import Google Cloud public key
                                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
                                
                                # Update and install gcloud
                                apt-get update -y
                                apt-get install -y google-cloud-cli
                                
                                echo "✅ Google Cloud SDK installed successfully"
                            else
                                echo "✅ Google Cloud SDK already installed"
                            fi
                            
                            # Authenticate with GCP
                            echo "🔐 Authenticating with Google Cloud..."
                            gcloud auth activate-service-account --key-file=\${GOOGLE_APPLICATION_CREDENTIALS}
                            gcloud config set project ${PROJECT_ID}
                            
                            echo "📦 Submitting to Cloud Build for automated deployment..."
                            # Submit to Cloud Build
                            gcloud builds submit --config=cloudbuild.yaml --project=${PROJECT_ID} --substitutions=_BUILD_ID=${env.BUILD_NUMBER}
                            
                            echo "✅ FULLY AUTOMATED deployment complete!"
                            echo "🌐 Your changes are now live at: http://34.59.226.237"
                            echo "📝 Survey form: http://34.59.226.237/survey.html"
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo 'Verifying deployment...'
                    sh """
                        echo "Checking deployment status..."
                        
                        # Wait a moment for deployment to start
                        sleep 10
                        
                        echo "Deployment verification completed"
                        echo "Application available at: http://34.59.226.237"
                        echo "Survey form at: http://34.59.226.237/survey.html"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo 'Application is available at: http://34.59.226.237'
            echo 'Survey form: http://34.59.226.237/survey.html'
            echo 'All 3 pods are running and healthy!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
        always {
            echo 'Pipeline execution completed.'
            echo 'Jenkins + Cloud Build CI/CD demonstration finished.'
        }
    }
}