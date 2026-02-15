# Project: Jenkins Docker Compose Setup with Nginx TLS

## Overview
This project sets up a **Jenkins** CI/CD server sitting behind an **Nginx** reverse proxy, orchestrated via **Docker Compose**. It features an automated local PKI (Public Key Infrastructure) service that generates self-signed TLS certificates for secure access (HTTPS).

**Key Components:**
*   **Jenkins:** The core CI/CD engine (Image: `jenkins:2.550-jdk25`). Configured to run on internal port 8080.
*   **Nginx:** A reverse proxy providing TLS termination (Image: `nginx:1.27-alpine`). Listens on host port `8443` and proxies to Jenkins.
*   **PKI Service:** A transient Alpine container that generates a private Certificate Authority (CA) and server certificates upon startup if they don't exist.

## Architecture
*   **Network:** `jenkins_net` (Bridge network). Jenkins is isolated and only accessible via Nginx.
*   **Persistence:**
    *   `./jenkins-home` -> `/var/jenkins_home` (Jenkins data)
    *   `./pki-data` -> `/pki` (Generated certificates)
    *   `./nginx-conf` -> `/etc/nginx/conf.d` (Nginx configuration)

## Prerequisites
*   Docker
*   Docker Compose

## Setup & Usage

### 1. Start the Environment
Run the following command in the project root:
```bash
docker-compose up -d
```
This will:
1.  Start the `pki` container to generate certificates (creates `ca.cert.pem`, `server.cert.pem`, etc. in `pki-data/`).
2.  Start `jenkins`.
3.  Start `nginx` (depends on `jenkins` and `pki`).

### 2. Accessing Jenkins
*   **URL:** `https://localhost:8443`
*   **TLS Warning:** Since the certificate is self-signed by a local private CA, your browser will warn you. You can safely proceed (or import `pki-data/ca.cert.pem` into your trust store).

### 3. Initial Unlock
To unlock Jenkins for the first time, you need the initial admin password.
*   **From Logs:** `docker logs lab_jenkins`
*   **From File:** `cat jenkins-home/secrets/initialAdminPassword`

## Configuration Details

### Nginx Configuration
The Nginx configuration is dynamically generated at runtime by the script `nginx/00-write-conf.sh`. This script overwrites `/etc/nginx/conf.d/default.conf` inside the container.
*   **Upstream:** `jenkins:8080`
*   **TLS:** Enforces TLS v1.2/v1.3.
*   **Max Body Size:** 64MB (useful for uploading large plugins or artifacts).

### Certificate Generation
Managed by `pki/gen-certs.sh`.
*   **CA Subject:** `/CN=Lab Private CA`
*   **Server Subject:** `CN=jenkins.lab.local` (configurable via `SERVER_CN` env var, defaults to `jenkins.lab.local`).
*   **SANs:** `jenkins.lab.local`, `localhost`, `127.0.0.1`.

## Development & Troubleshooting
*   **Re-generating Certs:** To force regeneration, delete the contents of `pki-data/` and restart the `pki` service.
    ```bash
    rm pki-data/*.pem
    docker-compose up pki
    ```
*   **Jenkins Plugins/Data:** All Jenkins configuration is stored in `jenkins-home/`. This directory is persistent across restarts.
