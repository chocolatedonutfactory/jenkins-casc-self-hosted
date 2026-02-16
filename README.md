# Jenkins Docker Compose with Keycloak OIDC Authentication

This project sets up a **Jenkins** CI/CD server, a **Keycloak** Identity Provider, and an **Nginx** reverse proxy, all orchestrated with **Docker Compose**. It demonstrates a complete "Configuration as Code" setup for Jenkins security using OpenID Connect (OIDC).

## Architecture

*   **Jenkins:** (Port 8443) Configured via JCasC to delegate authentication to Keycloak.
*   **Keycloak:** (Port 8444) Acts as the Identity Provider (IdP). Pre-loaded with a realm `jenkins-lab`.
*   **Nginx:** Handles TLS termination for both Jenkins and Keycloak.
*   **PKI:** Generates self-signed certificates for local HTTPS.

## Prerequisites
*   Docker
*   Docker Compose (v2 recommended)

## Setup & Usage

### 1. Configure Environment
Copy the example environment file:
```bash
cp .env.example .env
```
Edit `.env` to customize settings (optional).

### 2. Start the Environment
Use the provided management script to switch between environments.

**Development Environment (Bind Mounts, Debug Mode):**
```bash
./manage.sh dev up -d --build
```
This mounts local directories (`./jenkins-home`, `./keycloak-data`) for easy editing and debugging.

**Production-Like Environment (Named Volumes, Optimized, Auto-Restart):**
```bash
./manage.sh prod up -d --build
```
This uses persistent Docker volumes and production settings.

### 3. Trust Certificates
Since we use self-signed certs, you must trust the CA.
**Pop!_OS / Linux:**
```bash
sudo cp pki-data/ca.cert.pem /usr/local/share/ca-certificates/jenkins-lab-ca.crt
sudo update-ca-certificates
```
**Firefox:** Import `pki-data/ca.cert.pem` into Authorities and trust it for websites.

### 4. Log in
1.  Navigate to `https://localhost:8443`.
2.  Click **Login**. You should be redirected to `https://localhost:8444` (Keycloak).
3.  **Demo Users (Lab):**
    *   `admin` / `admin` (Full Admin - `jenkins-admins` group)
    *   `devuser` / `password` (Developer - `jenkins-developers` group)
    *   `normaluser` / `password` (Viewer - `jenkins-users` group)

### Keycloak Administration
*   **URL:** `https://localhost:8444/`
*   **Console:** Click "Administration Console".
*   **Admin Credentials:** `admin` / `admin` (Environment variables in `.env`)

## Configuration Details

### Keycloak Realm (`keycloak-data/jenkins-lab-realm.json`)
*   **Realm:** `jenkins-lab`
*   **Client:** `jenkins` (Client ID: `jenkins`, Secret: `jenkins-secret`)
*   **User:** `admin` (Password: `admin`)
*   **Group:** `jenkins-admins` (Mapped to Jenkins "Administer" permission)

### Jenkins Config (`jenkins-casc/jenkins.yaml`)
*   **Security Realm:** OIDC plugin configured to talk to Keycloak.
*   **Authorization:**
    *   `Overall/Administer`: Granted to group `jenkins-admins`.
    *   `Overall/Read`: Granted to `authenticated` users.

## Documentation
Additional setup guides are available in the `docs/` directory:
*   [User Management & Authorization](docs/USER_MANAGEMENT.md) - **New: Group-based access control**
*   [Azure AD Setup](docs/AZURE_AD_SETUP.md)
*   [Keycloak User Management](docs/KEYCLOAK_USER_MANAGEMENT.md)
*   [Project Overview (GEMINI)](docs/GEMINI.md)

## Troubleshooting
*   **Redirect Loops/Errors:** Ensure `localhost` resolves correctly and the certificate is trusted by your browser.
*   **Invalid Redirect URI:** Keycloak is strict. The redirect URI in Keycloak (`https://localhost:8443/securityRealm/finishLogin`) must match exactly what Jenkins sends.
