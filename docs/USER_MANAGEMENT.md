# User Management & Authorization

This project uses a group-based authorization strategy. Instead of assigning permissions to individual users, we map **Keycloak Groups** to **Jenkins Roles** using the Jenkins "Matrix Authorization Strategy" plugin and "Jenkins Configuration as Code" (JCasC).

## How it Works

1.  **Authentication**: Handled by Keycloak via OpenID Connect (OIDC).
2.  **Group Mapping**: During login, Keycloak sends the user's group memberships in a claim named `groups`.
3.  **Authorization**: Jenkins matches these group names against the configured Matrix Authorization strategy.

## Defined Roles & Groups

We have defined three primary tiers of access:

| Keycloak Group | Jenkins Permissions | Description |
| :--- | :--- | :--- |
| `jenkins-admins` | `Overall/Administer` | Full access to everything. |
| `jenkins-developers` | `Job/Build`, `Job/Read`, `View/Read` | Can view and run jobs, but cannot change system settings. |
| `jenkins-users` | `Overall/Read`, `Job/Read`, `View/Read` | Read-only access to view jobs and system status. |

## Example Users (Dev/Lab Environment)

| Username | Password | Group | Access Level |
| :--- | :--- | :--- | :--- |
| `admin` | `admin` | `jenkins-admins` | Full Administrator |
| `devuser` | `password` | `jenkins-developers` | Standard Engineer (Build access) |
| `normaluser` | `password` | `jenkins-users` | Auditor (Read-only) |

## Configuration Details

### 1. Keycloak Configuration
In the Keycloak Realm JSON (`keycloak-data/jenkins-lab-realm.json`), a **Protocol Mapper** of type `oidc-group-membership-mapper` is configured for the `jenkins` client. This ensures the `groups` claim is included in the ID Token.

### 2. Jenkins JCasC Configuration
In `jenkins-casc/jenkins.yaml`, the `authorizationStrategy` section uses the `projectMatrix` entries to map the groups:

```yaml
authorizationStrategy:
  projectMatrix:
    entries:
      - group:
          name: "jenkins-admins"
          permissions:
            - "Overall/Administer"
      - group:
          name: "jenkins-developers"
          permissions:
            - "Overall/Read"
            - "Job/Read"
            - "Job/Build"
            ...
```

## Adding New Users/Groups

1.  **Add Group to Keycloak**: Create the group in the Keycloak admin console (or update the realm JSON).
2.  **Assign User to Group**: Add the user to the relevant group in Keycloak.
3.  **Update Jenkins (if needed)**: If you create a *new* group type, you must add a corresponding entry in `jenkins-casc/jenkins.yaml` and reload the JCasC configuration (or restart Jenkins).
