import subprocess
import json
import urllib.request
import urllib.error
import os
import sys

def get_token():
    for var in ['GH_TOKEN', 'GITHUB_TOKEN']:
        val = os.environ.get(var)
        if val:
            return val
    try:
        p = subprocess.Popen(
            ['git', 'credential', 'fill'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        out, _ = p.communicate('protocol=https\nhost=github.com\n\n')
        for line in out.splitlines():
            if line.startswith('password='):
                return line.split('=', 1)[1].strip()
    except Exception as e:
        print(f"Error retrieving token: {e}")
    raise RuntimeError("Could not retrieve token")

def main():
    token = get_token()
    repo = "abhilashmamminiyan/manikutti_mobile"
    workflow = "pipeline.yml"
    url = f"https://api.github.com/repos/{repo}/actions/workflows/{workflow}/dispatches"

    payload = {
        "ref": "main",
        "inputs": {
            "deploy_to_firebase": "true"
        }
    }

    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Manikutti-Automation',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            print(f"[OK] Workflow dispatch triggered successfully! HTTP {resp.status}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
        sys.exit(1)

if __name__ == '__main__':
    main()
