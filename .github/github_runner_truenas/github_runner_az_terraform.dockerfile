# Use the official GitHub Runner image as the base
FROM myoung34/github-runner:latest

# Install dependencies
#USER root  # Ensure we have the necessary privileges
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    software-properties-common \
    ca-certificates \
    lsb-release \
    apt-transport-https

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install -y terraform

## Switch back to runner user
#USER runner
