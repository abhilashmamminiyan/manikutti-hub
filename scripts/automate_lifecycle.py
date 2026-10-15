import subprocess
import json
import urllib.request
import urllib.error
import time
import os
import sys
import argparse

def get_token():
    # 1. Environment variables
    for var in ['GH_TOKEN', 'GITHUB_TOKEN']:
        val = os.environ.get(var)
        if val:
            return val

    # 2. Git Credential Manager
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
        print(f"Warning: Git Credential Manager lookup failed: {e}")

    raise RuntimeError("Could not retrieve GitHub PAT from environment or Git Credential Manager")

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

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

def main():
    parser = argparse.ArgumentParser(description="Automate PR creation, CI monitoring, and merge")
    parser.add_argument("--repo", default="abhilashmamminiyan/manikutti_mobile", help="Owner/repo slug")
    parser.add_argument("--head", required=True, help="Head branch name")
    parser.add_argument("--base", default="main", help="Base branch name")
    parser.add_argument("--title", required=True, help="PR title")
    parser.add_argument("--body", default="", help="PR description")
    parser.add_argument("--auto-merge", action="store_true", default=True, help="Auto-merge when CI passes")
    parser.add_argument("--no-merge", dest="auto_merge", action="store_false", help="Do not merge PR")

    args = parser.parse_args()

    token = get_token()
    print("[INFO] Retrieved GitHub PAT successfully.")

    repo = args.repo
    head = args.head
    base = args.base
    title = args.title
    body = args.body or f"Automated Pull Request for feature branch {head}."

    # 1. Check existing PR
    print(f"[INFO] Checking for existing open PR for {head} -> {base}...")
    existing_url = f"https://api.github.com/repos/{repo}/pulls?head={repo.split('/')[0]}:{head}&state=open"
    existing = api_request(existing_url, token=token)

    pr_number = None
    pr_url = None
    if existing:
        pr_number = existing[0]['number']
        pr_url = existing[0]['html_url']
        print(f"[INFO] Found existing PR #{pr_number}: {pr_url}")
    else:
        # Also check if already closed/merged
        all_url = f"https://api.github.com/repos/{repo}/pulls?head={repo.split('/')[0]}:{head}&state=all"
        all_prs = api_request(all_url, token=token)
        if all_prs and all_prs[0].get('merged_at'):
            print(f"[MERGED] PR #{all_prs[0]['number']} is already merged!")
            return

        print(f"[INFO] Creating new PR for {head} -> {base}...")
        create_url = f"https://api.github.com/repos/{repo}/pulls"
        pr_payload = {
            "title": title,
            "head": head,
            "base": base,
            "body": body
        }
        res = api_request(create_url, method='POST', data=pr_payload, token=token)
        pr_number = res['number']
        pr_url = res['html_url']
        print(f"[OK] Created PR #{pr_number}: {pr_url}")

    # Check if PR was already merged immediately
    pr_details_url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}"
    pr_details = api_request(pr_details_url, token=token)
    if pr_details.get('merged'):
        print(f"[MERGED] PR #{pr_number} is already MERGED!")
        return

    # 2. Monitor GitHub Actions CI Runs
    print(f"\n[INFO] Monitoring GitHub Actions CI runs for PR #{pr_number}...")
    max_wait = 600  # 10 minutes
    start_time = time.time()
    last_status = None

    while time.time() - start_time < max_wait:
        # Check if PR has been merged by auto-merge action while waiting
        pr_details = api_request(pr_details_url, token=token)
        if pr_details.get('merged'):
            print(f"[MERGED] PR #{pr_number} has been MERGED!")
            return

        runs_url = f"https://api.github.com/repos/{repo}/actions/runs?branch={head}"
        try:
            runs_data = api_request(runs_url, token=token)
            runs = runs_data.get('workflow_runs', [])
            if runs:
                latest_run = runs[0]
                run_id = latest_run['id']
                status = latest_run['status']
                conclusion = latest_run['conclusion']
                run_name = latest_run.get('name', 'CI')

                current_status_str = f"Run #{run_id} ({run_name}): status={status}, conclusion={conclusion}"
                if current_status_str != last_status:
                    print(f"[{time.strftime('%H:%M:%S')}] {current_status_str}")
                    last_status = current_status_str

                if status == 'completed':
                    if conclusion == 'success':
                        print("[OK] GitHub Actions CI Pipeline PASSED successfully!")
                        break
                    else:
                        print(f"[FAILED] CI Pipeline finished with conclusion: {conclusion}")
                        # Fetch failed logs
                        logs_url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/jobs"
                        jobs_data = api_request(logs_url, token=token)
                        for job in jobs_data.get('jobs', []):
                            if job.get('conclusion') == 'failure':
                                print(f"\nFailed Job: {job.get('name')} (Status: {job.get('conclusion')})")
                                for step in job.get('steps', []):
                                    if step.get('conclusion') == 'failure':
                                        print(f"  [STEP FAILED] {step.get('name')}")
                        sys.exit(1)
        except Exception as e:
            print(f"Checking workflow run: {e}")
        time.sleep(10)

    # 3. Check PR Merge Status or Squash Merge
    if args.auto_merge:
        print(f"\n[INFO] Checking merge status of PR #{pr_number}...")
        pr_details = api_request(pr_details_url, token=token)
        if pr_details.get('merged'):
            print(f"[MERGED] PR #{pr_number} is already MERGED!")
        else:
            print(f"[INFO] Attempting to squash merge PR #{pr_number}...")
            merge_url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}/merge"
            merge_payload = {
                "commit_title": f"{title} (#{pr_number})",
                "merge_method": "squash"
            }
            try:
                merge_res = api_request(merge_url, method='PUT', data=merge_payload, token=token)
                if merge_res.get('merged'):
                    print(f"[SUCCESS] PR #{pr_number} successfully MERGED into {base}!")
                else:
                    print(f"Merge response: {merge_res}")
            except Exception as e:
                print(f"Merge error: {e}")
                sys.exit(1)

if __name__ == '__main__':
    main()
