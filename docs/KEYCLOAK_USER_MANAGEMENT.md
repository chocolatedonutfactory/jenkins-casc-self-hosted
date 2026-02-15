# Keycloak User Management for Jenkins Access

This guide explains how to manage users within your **Keycloak** Identity Provider to control access to **Jenkins**. Our Jenkins instance is configured to rely on Keycloak for authentication and uses groups from Keycloak to determine authorization (admin vs. non-admin roles).

## Keycloak Admin Console Access

1.  Open your browser and navigate to the Keycloak Administration Console: `https://jenkins.lab.local:8444/`.
2.  Click **"Administration Console"**.
3.  Log in with your Keycloak admin credentials (default: `admin` / `admin`).
4.  Select the `jenkins-lab` realm from the top-left dropdown.

---

## 1. Creating a New User

To create a user that can log in to Jenkins:

1.  In the Keycloak Admin Console for the `jenkins-lab` realm, go to **Users** (left menu) -> **Add user**.
2.  Fill in the user details:
    *   **Username:** `johndoe` (or any desired username)
    *   **Email:** `john.doe@example.com`
    *   **First Name:** `John`
    *   **Last Name:** `Doe`
    *   Ensure **Email Verified** is `ON` (or users will need to verify their email).
    *   Set **Enabled** to `ON`.
3.  Click **Create**.

### Set User Password

1.  After creating the user, go to the **Credentials** tab for that user.
2.  Click **Set password**.
3.  Enter and confirm a password.
4.  Optionally, set **Temporary** to `ON` if you want the user to change their password on first login.
5.  Click **Set password**.

---

## 2. Assigning Roles/Groups for Jenkins Access

Jenkins authorization is managed through groups in Keycloak and mapped in `jenkins-casc/jenkins.yaml`.

### For Admin Users (e.g., Jenkins Administrators)

To make a user a Jenkins administrator, you need to assign them to the `jenkins-admins` group. This group is mapped to the `Overall/Administer` permission in Jenkins.

1.  In the Keycloak Admin Console, go to **Users** -> Select your new user (`johndoe`).
2.  Go to the **Groups** tab.
3.  Click **Join group**.
4.  Select the `jenkins-admins` group from the list.
5.  Click **Join**.

The user `johndoe` will now have administrative privileges in Jenkins.

### For Non-Admin Users (e.g., Jenkins Regular Users)

If you want users to have read-only access or limited permissions (e.g., only build specific jobs), you would typically create a new group in Keycloak and map it to specific permissions in Jenkins.

#### Steps:

1.  **Create a new group in Keycloak:**
    *   Go to **Groups** (left menu) -> **Create group**.
    *   **Name:** `jenkins-users`
    *   Click **Create**.
2.  **Assign the user to the new group:**
    *   Go to **Users** -> Select your new user (`janedoe`).
    *   Go to the **Groups** tab.
    *   Click **Join group**.
    *   Select the `jenkins-users` group.
    *   Click **Join**.
3.  **Update `jenkins-casc/jenkins.yaml` for permissions:**
    *   You would need to edit the `jenkins-casc/jenkins.yaml` file to define permissions for this new group. For example:
        ```yaml
        # ...
        authorizationStrategy:
          projectMatrix:
            permissions:
              - "Overall/Administer:jenkins-admins"
              - "Overall/Read:jenkins-users" # New line for read-only users
              - "Overall/Read:authenticated"
              - "Overall/Read:anonymous"
        # ...
        ```
    *   After modifying `jenkins-casc/jenkins.yaml`, you would need to run `sudo docker compose up -d --force-recreate` to apply the JCasC changes.

---

## 3. Testing User Login to Jenkins

1.  Open your browser and navigate to Jenkins: `https://jenkins.lab.local:8443/`.
2.  Click **Login**.
3.  You will be redirected to the Keycloak login page.
4.  Enter the **Username** and **Password** of the user you just created (e.g., `johndoe` / `<password>`).
5.  After successful authentication, you will be redirected back to Jenkins, logged in with the permissions assigned through Keycloak groups.
    *   If `johndoe` is in `jenkins-admins`, they will be an admin.
    *   If `janedoe` is in `jenkins-users`, they will have the permissions defined for `jenkins-users` in Jenkins.

## Important Considerations

*   **Group Mapping:** Ensure that the `groupsFieldName` in `jenkins-casc/jenkins.yaml` is correctly set (it's currently `groups`). Keycloak needs to be configured to send group information in the OIDC tokens.
*   **Case Sensitivity:** Usernames and group names in Keycloak are often case-sensitive.
*   **Security:** For a production environment, you would refine the Jenkins permissions and Keycloak realm roles much more granularly.
