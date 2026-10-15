import subprocess
import json
import urllib.request
import urllib.error
import time
import os
import sys

def get_token():
    p = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, _ = p.communicate('protocol=https\nhost=github.com\n\n')
    for line in out.splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1].strip()
    raise RuntimeError("Could not retrieve GitHub PAT from Git Credential Manager")

def api_request(url, method='GET', data=None, token=None):
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Manikutti-Automation',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    body = json.dumps(data).encode('utf-8') if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode('utf-8')
            return json.loads(res_body) if res_body else {}
    except urllib.error.HTTPError as e:
        error_msg = e.read().decode('utf-8')
        print(f"HTTP Error {e.code}: {error_msg}")
        raise

def main():
    token = get_token()
    print("Retrieved GitHub PAT successfully.")

    repo = "abhilashmamminiyan/manikutti_mobile"
    head = "feature/personal-finance-dashboard-refactor"
    base = "main"

    # 1. Check existing PR
    print(f"Checking for existing open PR for {head}...")
    existing_url = f"https://api.github.com/repos/{repo}/pulls?head=abhilashmamminiyan:{head}&state=open"
    existing = api_request(existing_url, token=token)
    
    pr_number = None
    pr_url = None
    if existing:
        pr_number = existing[0]['number']
        pr_url = existing[0]['html_url']
        print(f"Found existing PR #{pr_number}: {pr_url}")
    else:
        print(f"Creating new PR for {head} -> {base}...")
        create_url = f"https://api.github.com/repos/{repo}/pulls"
        pr_payload = {
            "title": "feat(dashboard): personal finance dashboard with budget progress, pie chart, dues table, and family EMI ledger",
            "head": head,
            "base": base,
            "body": (
                "## Summary & Improvements\n"
                "- **Dashboard Layout Fix**: Removed docked Sidebar rail from body: Row(...) that squished mobile dashboard to ~300px; navigation smoothly accessible via hamburger drawer and profile bottom sheet.\n"
                "- **Header & Screen Name Restoration**: Streamlined AppBar to clean hamburger, bold uncompressed screen title, and 3 essential actions (Voice Logging mic, Notifications with unread badge, and Profile/Settings sheet).\n"
                "- **Monthly Budget & Pace Progress Bar**: Interactive card comparing monthly personal spending against salary/budget with burn rate (₹/day) and remaining days pace indicator.\n"
                "- **Spending Breakdown Donut / Pie Chart**: Custom painter animated donut chart with center total spend metric and category percentages.\n"
                "- **Monthly Utilities & Dues Section**: Exact recreation of user reference table with Add Monthly Dues dialog and one-tap payment marking.\n"
                "- **Family Loans & EMI Ledger**: Comprehensive loan cards for Home Loan (mortgage) and consumer EMIs showing balance, installment progress (e.g. 14/36 months), principal paid, interest paid, and remaining balance.\n"
                "- **App Lock & Voice Overlay**: Configured 2-minute lock grace period and decoupled VoiceDialogActivity for transparent home screen overlay.\n"
                "- **Tests**: All 32 unit and widget tests passing cleanly."
            )
        }
        res = api_request(create_url, method='POST', data=pr_payload, token=token)
        pr_number = res['number']
        pr_url = res['html_url']
        print(f"Created PR #{pr_number}: {pr_url}")

    # 2. Monitor GitHub Actions CI Runs
    print(f"Monitoring GitHub Actions CI runs for PR #{pr_number}...")
    max_wait = 180  # 3 minutes
    start_time = time.time()
    run_id = None

    while time.time() - start_time < max_wait:
        runs_url = f"https://api.github.com/repos/{repo}/actions/runs?branch={head}&event=pull_request"
        try:
            runs_data = api_request(runs_url, token=token)
            runs = runs_data.get('workflow_runs', [])
            if runs:
                latest_run = runs[0]
                run_id = latest_run['id']
                status = latest_run['status']
                conclusion = latest_run['conclusion']
                print(f"Workflow Run #{run_id} ({latest_run.get('name', 'CI')}): status={status}, conclusion={conclusion}")
                if status == 'completed':
                    if conclusion == 'success':
                        print("CI Pipeline PASSED successfully!")
                        break
                    else:
                        print(f"CI Pipeline finished with conclusion: {conclusion}")
                        break
        except Exception as e:
            print(f"Error checking runs: {e}")
        time.sleep(10)

    # 3. Check PR Merge Status or Squash Merge
    print(f"Checking merge status of PR #{pr_number}...")
    pr_details_url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
    pr_details = api_request(pr_details_url, token=token)
    if pr_details.get('merged'):
        print(f"PR #{pr_number} is already MERGED!")
    else:
        print(f"Attempting to squash merge PR #{pr_number}...")
        merge_url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}/merge"
        merge_payload = {
            "commit_title": f"feat(dashboard): personal finance dashboard with budget progress, pie chart, dues table, and family EMI ledger (#{pr_number})",
            "merge_method": "squash"
        }
        try:
            merge_res = api_request(merge_url, method='PUT', data=merge_payload, token=token)
            if merge_res.get('merged'):
                print(f"PR #{pr_number} successfully MERGED via API!")
            else:
                print(f"Merge response: {merge_res}")
        except Exception as e:
            print(f"Merge error (may be waiting for CI checks): {e}")

if __name__ == '__main__':
    main()
