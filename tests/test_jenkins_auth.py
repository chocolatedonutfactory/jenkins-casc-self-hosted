import requests
from bs4 import BeautifulSoup
import urllib3
import pytest
import os

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_env_vars():
    env_vars = {}
    if os.path.exists(".env"):
        with open(".env", "r") as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    key, value = line.strip().split("=", 1)
                    env_vars[key] = value
    return env_vars

env = get_env_vars()
LAB_DOMAIN = env.get("LAB_DOMAIN", "localhost")
NGINX_JENKINS_PORT = env.get("NGINX_JENKINS_PORT", "8443")
NGINX_KEYCLOAK_PORT = env.get("NGINX_KEYCLOAK_PORT", "8444")

JENKINS_URL = f"https://{LAB_DOMAIN}:{NGINX_JENKINS_PORT}"
KEYCLOAK_URL = f"https://{LAB_DOMAIN}:{NGINX_KEYCLOAK_PORT}"

print(f"Testing against JENKINS_URL: {JENKINS_URL}")
print(f"Testing against KEYCLOAK_URL: {KEYCLOAK_URL}")

def login_to_jenkins(username, password):
    session = requests.Session()
    session.verify = False

    # 1. Access Jenkins, which might return 403 with a meta refresh
    print(f"Accessing Jenkins for user: {username}")
    res = session.get(JENKINS_URL, allow_redirects=True)
    
    if res.status_code == 403:
        print("Got 403, attempting to follow commenceLogin")
        res = session.get(f"{JENKINS_URL}/securityRealm/commenceLogin?from=%2F", allow_redirects=True)

    # Check if we are on Keycloak login page by looking for the form
    soup = BeautifulSoup(res.text, 'html.parser')
    login_form = soup.find('form', id='kc-form-login')
    
    if not login_form:
        print(f"Could not find login form at {res.url}")
        return session, res

    login_url = login_form['action']
    
    # 2. Submit credentials to Keycloak
    payload = {
        'username': username,
        'password': password,
        'credentialId': ''
    }
    
    print(f"Submitting credentials to Keycloak: {login_url}")
    res = session.post(login_url, data=payload, allow_redirects=True)
    
    return session, res

@pytest.mark.parametrize("username,password,role", [
    ("admin", "admin", "admin"),
    ("devuser", "password", "developer"),
    ("normaluser", "password", "user"),
])
def test_user_permissions(username, password, role):
    session, res = login_to_jenkins(username, password)
    
    assert res.status_code == 200
    assert "Dashboard - Jenkins" in res.text, f"User {username} did not reach the dashboard."
    
    if role == "admin":
        # Admin should see "Manage Jenkins" and "New Item"
        assert "Manage Jenkins" in res.text
        assert "New Item" in res.text
    else:
        # Non-admins should NOT see "Manage Jenkins"
        assert "Manage Jenkins" not in res.text
        # In this setup, developers and users don't have Job/Create
        assert "New Item" not in res.text

    # Verify basic access to the main panel
    assert 'id="main-panel"' in res.text

def test_invalid_login():
    session, res = login_to_jenkins("invalid", "wrong")
    assert "Invalid username or password." in res.text
