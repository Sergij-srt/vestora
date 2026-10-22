const http = require('http');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

class CdpClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.id = 1;
    this.pending = new Map();
    this.networkLogs = [];
    this.consoleLogs = [];

    this.ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(msg.error);
        else resolve(msg.result);
      } else if (msg.method) {
        if (msg.method === 'Network.responseReceived') {
          const resp = msg.params.response;
          if (resp.url.includes('unsplash') || resp.status >= 400) {
            this.networkLogs.push(`[HTTP ${resp.status}] ${resp.url.substring(0, 80)}`);
          }
        } else if (msg.method === 'Network.loadingFailed') {
          this.networkLogs.push(`[FAILED] ${msg.params.errorText} - ${msg.params.type}`);
        } else if (msg.method === 'Runtime.consoleAPICalled') {
          const args = msg.params.args.map(a => a.value || JSON.stringify(a)).join(' ');
          this.consoleLogs.push(`[${msg.params.type}] ${args}`);
        }
      }
    };
  }

  async ready() {
    if (this.ws.readyState === WebSocket.OPEN) return;
    await new Promise((resolve, reject) => {
      this.ws.onopen = resolve;
      this.ws.onerror = reject;
    });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = this.id++;
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.ws.close();
  }
}

async function run() {
  const chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
  const userDataDir = path.join(process.env.TEMP || 'C:\\Windows\\Temp', 'cdp_net_' + Date.now());

  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--user-data-dir=' + userDataDir,
    '--window-size=412,890',
    '--disable-gpu',
    'http://127.0.0.1:8080'
  ]);

  try {
    let wsUrl = null;
    for (let i = 0; i < 30; i++) {
      await sleep(500);
      try {
        const pages = await new Promise((resolve, reject) => {
          http.get('http://127.0.0.1:9222/json', (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve(JSON.parse(data)));
          }).on('error', reject);
        });
        const target = pages.find(p => p.type === 'page' && p.url.includes('8080'));
        if (target && target.webSocketDebuggerUrl) {
          wsUrl = target.webSocketDebuggerUrl;
          break;
        }
      } catch (e) {}
    }

    const client = new CdpClient(wsUrl);
    await client.ready();
    await client.send('Page.enable');
    await client.send('Runtime.enable');
    await client.send('Network.enable');

    console.log('Monitoring network for 8 seconds...');
    await sleep(8000);

    console.log('\n--- NETWORK LOGS ---');
    console.log(`Captured ${client.networkLogs.length} items`);
    client.networkLogs.forEach(l => console.log(l));

    console.log('\n--- CONSOLE LOGS ---');
    console.log(`Captured ${client.consoleLogs.length} items`);
    client.consoleLogs.forEach(l => console.log(l));

    client.close();
  } finally {
    chrome.kill();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

run();
