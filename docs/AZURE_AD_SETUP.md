# Jenkins with Azure AD (Direct OIDC Integration)

This guide explains how to configure Jenkins to authenticate *directly* against **Azure Active Directory (Microsoft Entra ID)** using the OpenID Connect (OIDC) protocol. This replaces Keycloak as the identity provider for Jenkins.

## Prerequisites

1.  Access to an **Azure AD Tenant**.
2.  Permission to register applications in Azure AD.
3.  This project's environment running locally.

## Step 1: Register Jenkins in Azure AD

1.  Log in to the [Azure Portal](https://portal.azure.com).
2.  Navigate to **Microsoft Entra ID** -> **App registrations** -> **New registration**.
3.  **Register the application:**
    *   **Name:** `Jenkins Local Lab`
    *   **Supported account types:** Single tenant (or Multitenant if needed).
    *   **Redirect URI (Web):** `https://jenkins.lab.local:8443/securityRealm/finishLogin`
    *   Click **Register**.
4.  **Copy IDs:**
    *   **Application (client) ID**
    *   **Directory (tenant) ID**
5.  **Create Client Secret:**
    *   Go to **Certificates & secrets** -> **Client secrets** -> **New client secret**.
    *   Add a description and expiry.
    *   **Copy the Value** immediately (you won't see it again).
6.  **Configure Token Claims (Optional but Recommended):**
    *   Go to **Token configuration** -> **Add optional claim**.
    *   Select **ID**, choose `email`, `preferred_username`.
    *   Select **Access**, choose `email`.
    *   Click **Add**.
7.  **Configure Group Claims (For Authorization):**
    *   Go to **Token configuration** -> **Add groups claim**.
    *   Select **Security groups** (or generic groups as needed).
    *   Expand **ID** and **Access**.
    *   **Customize token properties by type:**
        *   Group ID: `groups` (Azure usually sends Object IDs).
    *   *Note: To receive Group Names instead of IDs, you need to "Emit groups as role claims" or use an Azure AD specific plugin, but standard OIDC usually deals in IDs.*

## Step 2: Configure Jenkins Environment

You need to update your `.env` file to point Jenkins to Azure AD instead of Keycloak.

1.  Open `.env` in the project root.
2.  Update the **OIC Configuration** section:

```ini
# Azure AD Application ID
OIC_CLIENT_ID=<YOUR_AZURE_CLIENT_ID>

# Azure AD Client Secret
OIC_CLIENT_SECRET=<YOUR_AZURE_CLIENT_SECRET>

# Azure AD OIDC Discovery URL
# Replace <YOUR_TENANT_ID> with your Directory (tenant) ID
OIC_WELL_KNOWN_URL=https://login.microsoftonline.com/<YOUR_TENANT_ID>/v2.0/.well-known/openid-configuration
```

## Step 3: Adjust Authorization (Jenkins Configuration)

Azure AD typically returns **Group Object IDs (UUIDs)** in the `groups` claim, not friendly names like `jenkins-admins`. You have two options:

### Option A: Use Azure Group Object IDs in Jenkins (Easiest)
1.  Find the Object ID of the Azure AD group you want to be admins.
2.  Update `jenkins-casc/jenkins.yaml`:
    ```yaml
    authorizationStrategy:
      projectMatrix:
        permissions:
          # Replace <AZURE_GROUP_OBJECT_ID> with the actual UUID
          - "Overall/Administer:<AZURE_GROUP_OBJECT_ID>"
          - "Overall/Read:authenticated"
    ```

### Option B: Configure Azure to send Group Names (Advanced)
This requires editing the App Manifest in Azure or using "App Roles".
1.  In Azure AD App Registration -> **App roles**.
2.  Create a role named `jenkins-admins`.
3.  Assign this role to your user or group in "Enterprise Applications" -> "Users and groups".
4.  Azure will send this in the `roles` claim.
5.  You may need to update `jenkins.yaml` to look at the `roles` field instead of `groups` if the OIDC plugin supports generic claim mapping for groups (standard OIDC plugin usually looks at a specific field).

## Step 4: Apply Changes

1.  Restart the stack to pick up the new environment variables and config:
    ```bash
    docker compose down
    docker compose up -d
    ```
2.  Navigate to `https://jenkins.lab.local:8443/`.
3.  Click Login. You should be redirected to Microsoft.

## Troubleshooting

*   **"Reply URL does not match"**: Ensure `https://jenkins.lab.local:8443/securityRealm/finishLogin` is exactly what is in Azure AD Redirect URIs.
*   **"User is not authorized"**: This usually means authentication worked (you are logged in), but Authorization failed. Check your `jenkins.yaml` matrix.
    *   **Quick Fix:** Temporarily enable "Logged-in users can do anything" or ensure your user ID (email) is explicitly added to the matrix if group mapping fails.