pipeline {
    agent any // Runs on any available Jenkins agent

    environment {
        NODE_VERSION = '20.17.0' // Or whatever Node.js version Postiz requires
        // PR_NUMBER is already correctly set from Jenkins environment variable CHANGE_ID for PRs
        // IMAGE_TAG needs to point to YOUR GHCR
        // MODIFIED: Define owner and image name for clarity and correctness
        GITHUB_OWNER = 'cyberincome' // CHANGED: Your GitHub username
        IMAGE_BASENAME = 'postiz-app-pr' // CHANGED: Base name for your PR images
        IMAGE_TAG = "ghcr.io/${GITHUB_OWNER}/${IMAGE_BASENAME}:${env.CHANGE_ID}"
    }

    stages {
        stage('Checkout Repository') {
            steps {
                checkout scm // Checks out the code from the SCM configured in Jenkins (your fork)
            }
        }

        stage('Check Node.js and npm') {
            // This stage assumes Node.js is available on the Jenkins agent or via a tool installer.
            // If using a Dockerized Jenkins agent, Node.js might already be in the agent image.
            // Alternatively, you might use a 'tools' directive or a Node.js plugin.
            // For simplicity, keeping sh calls but be mindful of agent setup.
            steps {
                script {
                    // Example: If you have a specific Node.js tool configured in Jenkins:
                    // tool name: "${NODE_VERSION}", type: 'jenkins.plugins.nodejs.tools.NodeJSInstallation'
                    // sh "node -v"
                    // sh "npm -v"
                    // For now, assuming node is in PATH
                    sh "echo Node version: $(node -v || echo 'Node not found in PATH')"
                    sh "echo npm version: $(npm -v || echo 'npm not found in PATH')"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                // Consider using pnpm if the project uses it consistently, like in Dockerfile.dev
                // sh 'pnpm install --frozen-lockfile' 
                sh 'npm ci' // 'npm ci' is good for CI as it uses package-lock.json
            }
        }

        stage('Build Project') {
            steps {
                // If the project uses pnpm scripts:
                // sh 'pnpm run build'
                sh 'npm run build'
            }
        }
        
        stage('Build and Push Docker Image') {
            when {
                // Only run if CHANGE_ID (PR number) is available
                expression { return env.CHANGE_ID != null } 
            }
            steps {
                // Ensure Docker is available on the Jenkins agent
                // GITHUB_PASS should be a Jenkins secret-text credential with your PAT
                withCredentials([string(credentialsId: 'gh-pat', variable: 'GITHUB_PAT_TOKEN')]) { // MODIFIED: Renamed variable for clarity
                    sh '''
                        echo "$GITHUB_PAT_TOKEN" | docker login ghcr.io -u "${GITHUB_OWNER}" --password-stdin 
                    ''' // MODIFIED: Use GITHUB_OWNER variable
                    // Build Docker image
                    sh '''
                        echo "Building Docker image: $IMAGE_TAG"
                        docker build -f Dockerfile.dev -t "$IMAGE_TAG" . 
                    ''' // Using "" around $IMAGE_TAG is safer
                    // Push Docker image to GitHub Container Registry
                    sh '''
                        echo "Pushing Docker image: $IMAGE_TAG"
                        docker push "$IMAGE_TAG"
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Build completed successfully!'
            // You could add a step here to comment on the GitHub PR with the image name if desired
            // using a GitHub API call or a Jenkins plugin.
        }
        failure {
            echo 'Build failed!'
            // Could add notification steps here.
        }
    }
}