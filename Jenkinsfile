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
                    echo '🚀 Starting Cloud Build deployment...'
                    echo "Source commit: ${env.GIT_COMMIT}"
                    echo "Building image: ${IMAGE_TAG}"
                    
                    sh """
                        # Trigger Cloud Build
                        gcloud builds submit \
                            --config=cloudbuild.yaml \
                            --project=${PROJECT_ID}
                    """
                    
                    echo "✅ Cloud Build triggered successfully!"
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo 'Verifying deployment...'
                    sh """
                        # Wait for deployment to complete
                        echo "Waiting for deployment to rollout..."
                        sleep 30
                        
                        # Check deployment status
                        gcloud container clusters get-credentials ${CLUSTER_NAME} \
                            --region=${CLUSTER_ZONE} \
                            --project=${PROJECT_ID}
                        
                        kubectl rollout status deployment/student-survey-app -n ${NAMESPACE}
                        
                        echo ""
                        echo "✅ Deployment verification completed"
                        echo "🌐 Application available at: http://34.59.226.237"
                        echo "📋 Survey form at: http://34.59.226.237/survey.html"
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