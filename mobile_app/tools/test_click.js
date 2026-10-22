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
    this.consoleLogs = [];
    this.ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(msg.error);
        else resolve(msg.result);
      } else if (msg.method) {
        if (msg.method === 'Runtime.consoleAPICalled') {
          const args = msg.params.args.map(a => a.value || JSON.stringify(a)).join(' ');
          this.consoleLogs.push(`[${msg.params.type}] ${args}`);
        } else if (msg.method === 'Runtime.exceptionThrown') {
          const desc = msg.params.exceptionDetails?.exception?.description || msg.params.exceptionDetails?.text;
          this.consoleLogs.push(`[EXCEPTION] ${desc}`);
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

  async click(x, y) {
    await this.send('Input.dispatchMouseEvent', {
      type: 'mouseMoved',
      x,
      y
    });
    await sleep(40);
    await this.send('Input.dispatchMouseEvent', {
      type: 'mousePressed',
      x,
      y,
      button: 'left',
      clickCount: 1
    });
    await sleep(40);
    await this.send('Input.dispatchMouseEvent', {
      type: 'mouseReleased',
      x,
      y,
      button: 'left',
      clickCount: 1
    });
  }

  async screenshot(outPath) {
    const res = await this.send('Page.captureScreenshot', {
      format: 'png',
      quality: 90
    });
    if (res && res.data) {
      fs.writeFileSync(outPath, Buffer.from(res.data, 'base64'));
      console.log(`Saved: ${outPath}`);
    }
  }

  close() {
    this.ws.close();
  }
}

async function run() {
  const screenshotsDir = path.join(__dirname, '..', 'screenshots');
  const chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
  const userDataDir = path.join(process.env.TEMP || 'C:\\Windows\\Temp', 'vestora_cdp_' + Date.now());

  console.log('Launching Headless Chrome (412x890)...');
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

    console.log('Waiting 3.5s for Flutter boot...');
    await sleep(3500);

    await client.screenshot(path.join(screenshotsDir, '01_auth_screen.png'));

    // In 01_auth_screen.png, the button "Продовжити як гість" is at y ≈ 865 in 412x890!
    // Let's check where the button is.
    // Let's try clicking at x=206, y=865 (and if needed 770, 780, 800)
    console.log('Clicking "Продовжити як гість (Демо-режим)" at x=206, y=865...');
    await client.click(206, 865);
    await sleep(1500);

    // If still on auth, also try y=770 or y=820
    await client.click(206, 820);
    await sleep(1500);

    // Let's also test Google Sign In button at x=206, y=385
    // In case guest button is slightly different, Google button is at y=385!
    // But let's check screenshot after guest click
    await client.screenshot(path.join(screenshotsDir, '02_after_click.png'));

    client.close();
  } finally {
    chrome.kill();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

run();
