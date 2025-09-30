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
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh """
                        docker build --platform linux/amd64 -t ${IMAGE_TAG} .
                        docker tag ${IMAGE_TAG} gcr.io/${PROJECT_ID}/student-survey:latest
                    """
                }
            }
        }
        
        stage('Push to GCR') {
            steps {
                script {
                    echo 'Pushing image to Google Container Registry...'
                    sh """
                        gcloud auth configure-docker --quiet
                        docker push ${IMAGE_TAG}
                        docker push gcr.io/${PROJECT_ID}/student-survey:latest
                    """
                }
            }
        }
        
        stage('Deploy to GKE') {
            steps {
                script {
                    echo 'Deploying to Google Kubernetes Engine...'
                    sh """
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --region=${CLUSTER_ZONE} --project=${PROJECT_ID}
                        
                        # Update deployment with new image
                        kubectl set image deployment/student-survey-app student-survey=${IMAGE_TAG} -n ${NAMESPACE}
                        
                        # Wait for rollout to complete
                        kubectl rollout status deployment/student-survey-app -n ${NAMESPACE}
                        
                        # Verify deployment
                        kubectl get pods -n ${NAMESPACE}
                        kubectl get services -n ${NAMESPACE}
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh """
                        # Get external IP
                        EXTERNAL_IP=\$(kubectl get service student-survey-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                        echo "Application URL: http://\$EXTERNAL_IP"
                        
                        # Wait for service to be ready
                        sleep 30
                        
                        # Health check
                        curl -f http://\$EXTERNAL_IP || exit 1
                        echo "Health check passed!"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            script {
                sh """
                    EXTERNAL_IP=\$(kubectl get service student-survey-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                    echo "🎉 Deployment successful!"
                    echo "Application is available at: http://\$EXTERNAL_IP"
                    echo "Survey form: http://\$EXTERNAL_IP/survey.html"
                """
            }
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f'
        }
    }
}