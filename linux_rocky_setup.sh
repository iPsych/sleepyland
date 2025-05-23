#!/bin/bash

# Function to install Docker on Rocky Linux
install_docker() {
    echo "[INFO] Docker not found. Attempting to install Docker..."

    # Update package database and install dependencies
    sudo dnf -y update
    sudo dnf -y install dnf-plugins-core

    # Add Docker repository
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Install Docker
    sudo dnf -y install docker-ce docker-ce-cli containerd.io

    # Start and enable Docker service
    echo "[INFO] Starting Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add the current user to the Docker group (requires re-login to take effect)
    sudo usermod -aG docker $USER

    # Wait for Docker to be available
    echo "[INFO] Waiting for Docker to start..."
    while ! docker info &> /dev/null; do
        echo "[INFO] Docker not ready yet. Retrying in 2 seconds..."
        sleep 2
    done
    echo "[INFO] Docker is now available."

    # Verify Docker installation
    if command -v docker &> /dev/null; then
        echo "[INFO] Docker installed successfully."
    else
        echo "[ERROR] Docker installation failed. Please install it manually and try again."
        exit 1
    fi
}

# Check if Docker is installed; if not, install it
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "[INFO] Docker is already installed."
fi

# Ensure Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "[INFO] Docker Compose not found. Installing Docker Compose..."
    sudo dnf -y install docker-compose-plugin
    if ! command -v docker-compose &> /dev/null; then
        echo "[ERROR] Docker Compose installation failed. Please install it manually and try again."
        exit 1
    fi
else
    echo "[INFO] Docker Compose is installed."
fi

# Function to pull images from Docker Hub
pull_images() {
    echo "[INFO] Pulling pre-built images from Docker Hub..."
    docker pull bspsupsi/sleepyland:gui
    docker pull bspsupsi/sleepyland:manager-api
    docker pull bspsupsi/sleepyland:usleepyland
    docker pull bspsupsi/sleepyland:notebook
    docker pull bspsupsi/sleepyland:nsrr-download
    docker pull bspsupsi/sleepyland:wild-to-fancy
    if [ $? -eq 0 ]; then
        echo "[INFO] Docker images pulled successfully."
    else
        echo "[ERROR] Failed to pull Docker images. Please check your internet connection or Docker Hub access."
        exit 1
    fi
}

force_pull=true

# Pull Docker images if there were changes in the repository
if [ "$force_pull" = true ]; then
    pull_images
else
    echo "[INFO] No Docker images pull required."
fi

# Start Docker containers with --force-recreate
echo "[INFO] Starting Docker containers with forced recreation..."
docker compose -f docker-compose.yml -p sleepyland up -d --force-recreate
if [ $? -eq 0 ]; then
    echo "[INFO] Docker containers started successfully."
else
    echo "[ERROR] Failed to start Docker containers."
    exit 1
fi

# Open the web interface in the default browser
echo "[INFO] Opening the web interface in the default browser..."
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:8887" &> /dev/null
    echo "[INFO] Web interface opened successfully."
else
    echo "[ERROR] Failed to open the web interface. Please check your default browser settings."
    exit 1
fi
