import os
import hmac
import json
import hashlib
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

# Configuration from environment
GITHUB_SECRET = os.environ["GITHUB_WEBHOOK_SECRET"]  # Webhook secret from GitHub
GITHUB_PAT = os.environ["GITHUB_PAT"]                # GitHub PAT with admin:org scope
GITHUB_ORG = os.environ["GITHUB_ORG"]                # GitHub organization name
GITHUB_REPO = os.environ["GITHUB_REPO"]                # GitHub repository name
NOMAD_JOB_TEMPLATE = os.environ["NOMAD_JOB_TEMPLATE"] # Path to Nomad job template

def fetch_registration_token():
    import requests
    #If using a GitHub organization url = f"https://api.github.com/orgs/{GITHUB_ORG}/actions/runners/registration-token"
    url = f"https://api.github.com/repos/{GITHUB_ORG}/{GITHUB_REPO}/actions/runners/registration-token"
    headers = {
        "Authorization": f"token {GITHUB_PAT}",
        "Accept": "application/vnd.github+json",
    }
    print(f"Requesting token from GitHub at {url}")
    response = requests.post(url, headers=headers)
    print("GitHub API response:", response.status_code, response.text)
    response.raise_for_status()
    return response.json()["token"]

def trigger_runner_job(token: str):
    cmd = [
        "nomad", "job", "dispatch", 
        #If using a GitHub Organization "-var", f"github_url=https://github.com/orgs/{GITHUB_ORG}/{GITHUB_REPO}",
        "-meta", f"github_url=https://github.com/{GITHUB_ORG}/{GITHUB_REPO}",
        "-meta", f"runner_token={token}", 
        "-meta", "runner_labels=nomad",
        NOMAD_JOB_TEMPLATE
    ]
    print("Running Nomad job with command:", " ".join(cmd))
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print("Nomad job failed:", e.stderr)
        raise

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers["Content-Length"])
        payload = self.rfile.read(length)

        # Verify GitHub signature
        signature = self.headers.get("X-Hub-Signature-256")
        if not signature:
            self.send_response(403)
            self.end_headers()
            return

        digest = hmac.new(GITHUB_SECRET.encode(), payload, hashlib.sha256).hexdigest()
        expected = f"sha256={digest}"
        if not hmac.compare_digest(signature, expected):
            self.send_response(403)
            self.end_headers()
            return

        event = self.headers.get("X-GitHub-Event")
        if event != "workflow_job":
            self.send_response(200)
            self.end_headers()
            return

        body = json.loads(payload)
        action = body.get("action")
        labels = [l.lower() for l in body["workflow_job"].get("labels", [])]

        # Only react to queued jobs that match desired label
        if action == "queued" and "nomad" in labels:
            try:
                token = fetch_registration_token()
                trigger_runner_job(token)
                self.send_response(202)
            except Exception as e:
                print(f"Error launching runner job: {e}")
                self.send_response(500)
        else:
            self.send_response(200)

        self.end_headers()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    server = HTTPServer(("", port), WebhookHandler)
    print(f"Webhook server listening on port {port}...")
    server.serve_forever()
