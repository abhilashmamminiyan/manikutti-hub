#!/usr/bin/env node
/**
 * AI-First Crash & Telemetry Reader for Manikutti Hub
 *
 * Autonomously aggregates:
 *   1. Firebase Crashlytics Top Issues + Latest Events via local `firebase mcp --only crashlytics`
 *   2. Web/Mobile Error_Logs telemetry via `/api/telemetry/errors` (when AI_TELEMETRY_KEY is set)
 *   3. Connected Android device `adb logcat` crash buffer (when USB/emulator attached)
 *
 * Usage:
 *   node scripts/read_crashes.mjs
 *   node scripts/read_crashes.mjs --issue <issueId>
 *   node scripts/read_crashes.mjs --json
 */

import { execSync, spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const HUB_ROOT = path.resolve(__dirname, '..');
const MOBILE_ROOT = path.join(HUB_ROOT, 'manikutti_mobile');
const APP_ID = '1:945226005596:android:a8d62b7b8f49beb4cdba99';
const PROD_URL = process.env.MANIKUTTI_API_URL || 'https://manikutti.vercel.app';

const args = process.argv.slice(2);
const asJson = args.includes('--json');
const issueIdx = args.indexOf('--issue');
const specificIssueId = issueIdx !== -1 ? args[issueIdx + 1] : null;
const limitIdx = args.indexOf('--limit');
const pageSize = limitIdx !== -1 ? parseInt(args[limitIdx + 1], 10) || 15 : 15;

async function callFirebaseMcp(toolCalls) {
  const fbScript =
    process.platform === 'win32'
      ? path.join(process.env.APPDATA || '', 'npm', 'node_modules', 'firebase-tools', 'lib', 'bin', 'firebase.js')
      : null;

  const useDirectNode = Boolean(fbScript && fs.existsSync(fbScript));
  const cmd = useDirectNode ? process.execPath : 'firebase';
  const cmdArgs = useDirectNode
    ? [fbScript, 'mcp', '--only', 'crashlytics', '--dir', MOBILE_ROOT]
    : ['mcp', '--only', 'crashlytics', '--dir', MOBILE_ROOT];

  return new Promise((resolve) => {
    const child = spawn(cmd, cmdArgs, {
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    let stdoutBuf = '';
    let stderrBuf = '';
    const responses = new Map();
    let initialized = false;
    let nextId = 10;
    const expectedIds = new Set();

    const finish = () => {
      try {
        child.kill();
      } catch {}
      const out = Object.fromEntries(responses);
      if (stderrBuf.trim() && Object.values(out).some((v) => v?.error)) {
        out._stderr = stderrBuf.trim().slice(-800);
      }
      resolve(out);
    };

    const timer = setTimeout(() => {
      for (const [k, v] of responses.entries()) {
        if (v && v.pending) responses.set(k, { error: 'MCP call timed out before response' });
      }
      finish();
    }, 20000);

    child.stderr.on('data', (chunk) => {
      stderrBuf += chunk.toString();
    });

    child.stdout.on('data', (chunk) => {
      stdoutBuf += chunk.toString();
      const lines = stdoutBuf.split('\n');
      stdoutBuf = lines.pop() ?? '';
      for (const raw of lines) {
        const line = raw.trim();
        if (!line) continue;
        try {
          const msg = JSON.parse(line);
          if (msg.id === 1 && !initialized) {
            initialized = true;
            child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
            for (const call of toolCalls) {
              const id = nextId++;
              expectedIds.add(id);
              responses.set(call.key, { pending: true });
              child.stdin.write(
                JSON.stringify({
                  jsonrpc: '2.0',
                  id,
                  method: 'tools/call',
                  params: { name: call.name, arguments: call.arguments },
                }) + '\n'
              );
            }
          } else if (expectedIds.has(msg.id)) {
            const call = toolCalls[msg.id - 10];
            if (call) {
              responses.set(call.key, msg.error ? { error: msg.error } : msg.result);
            }
            if ([...responses.values()].every((v) => !v.pending)) {
              clearTimeout(timer);
              finish();
            }
          }
        } catch {
          // Ignore non-JSON preamble
        }
      }
    });

    child.on('error', (err) => {
      clearTimeout(timer);
      resolve({ _spawnError: err.message });
    });

    child.stdin.write(
      JSON.stringify({
        jsonrpc: '2.0',
        id: 1,
        method: 'initialize',
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {},
          clientInfo: { name: 'manikutti-crash-reader', version: '1.0.0' },
        },
      }) + '\n'
    );
  });
}

async function fetchBackendTelemetry() {
  const key = process.env.AI_TELEMETRY_KEY?.trim();
  if (!key) {
    return { skipped: 'AI_TELEMETRY_KEY env var not set (admin UI available at /admin -> Error & Crash Logs)' };
  }
  try {
    const res = await fetch(`${PROD_URL}/api/telemetry/errors?limit=${pageSize}`, {
      headers: { 'x-ai-telemetry-key': key },
    });
    const text = await res.text();
    try {
      return { status: res.status, data: JSON.parse(text) };
    } catch {
      return { status: res.status, raw: text.slice(0, 500) };
    }
  } catch (err) {
    return { error: err.message };
  }
}

function readConnectedAdbCrashes() {
  try {
    const devicesRaw = execSync('adb devices', { encoding: 'utf8', timeout: 4000 });
    const devices = devicesRaw
      .split('\n')
      .slice(1)
      .map((l) => l.trim().split(/\s+/))
      .filter((parts) => parts.length >= 2 && parts[1] === 'device')
      .map((parts) => parts[0]);

    if (devices.length === 0) return [];

    return devices.map((serial) => {
      try {
        const log = execSync(
          `adb -s ${serial} logcat -d -t 300 -v time AndroidRuntime:E flutter:E MlKitInitProvider:E *:S`,
          { encoding: 'utf8', timeout: 5000 }
        );
        const filtered = log
          .split('\n')
          .filter((l) => l.includes('manikutti') || l.includes('FATAL EXCEPTION') || l.includes('flutter'))
          .slice(-60)
          .join('\n');
        return { serial, recentLogLines: filtered || '(no recent manikutti/fatal entries)' };
      } catch (e) {
        return { serial, error: e.message };
      }
    });
  } catch {
    return [];
  }
}

function mcpText(res) {
  if (!res || res.error) return JSON.stringify(res?.error || res, null, 2);
  const parts = res.content || [];
  const joined = parts.map((p) => p.text || JSON.stringify(p)).join('\n');
  if (joined.includes('404, Requested entity was not found')) {
    return `${joined}\n(Hint: Crashlytics has no uploaded events yet or has not been enabled for this Android app in Firebase Console.)`;
  }
  return joined;
}

const mcpCalls = specificIssueId
  ? [
      { key: 'issue', name: 'crashlytics_get_issue', arguments: { appId: APP_ID, issueId: specificIssueId } },
      { key: 'events', name: 'crashlytics_list_events', arguments: { appId: APP_ID, filter: { issueId: specificIssueId }, pageSize: 5 } },
    ]
  : [
      { key: 'topIssues', name: 'crashlytics_get_report', arguments: { appId: APP_ID, report: 'topIssues', pageSize } },
    ];

const [crashlytics, telemetry, adb] = await Promise.all([
  callFirebaseMcp(mcpCalls),
  fetchBackendTelemetry(),
  Promise.resolve(readConnectedAdbCrashes()),
]);

const report = {
  generatedAt: new Date().toISOString(),
  appId: APP_ID,
  mobileDirExists: fs.existsSync(MOBILE_ROOT),
  crashlytics: Object.fromEntries(Object.entries(crashlytics).map(([k, v]) => [k, mcpText(v)])),
  backendTelemetry: telemetry,
  connectedDevices: adb,
};

if (asJson) {
  console.log(JSON.stringify(report, null, 2));
} else {
  console.log('=== FIREBASE CRASHLYTICS ===');
  for (const [k, text] of Object.entries(report.crashlytics)) {
    console.log(`--- ${k} ---\n${text}\n`);
  }
  console.log('=== BACKEND / API TELEMETRY ===');
  console.log(JSON.stringify(report.backendTelemetry, null, 2));
  console.log('\n=== CONNECTED ADB DEVICES ===');
  console.log(JSON.stringify(report.connectedDevices, null, 2));
}
