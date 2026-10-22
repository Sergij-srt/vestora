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

  async eval(expr) {
    const res = await this.send('Runtime.evaluate', {
      expression: expr,
      returnByValue: true,
      awaitPromise: true
    });
    return res?.result?.value;
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
      console.log(`Saved screenshot: ${outPath}`);
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

    console.log('Setting SharedPreferences in localStorage and reloading...');
    await client.eval(`
      const user = {
        id: 'usr_olena',
        email: 'olena.fashion@gmail.com',
        displayName: 'Олена Шевченко',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
        method: 'google',
        createdAt: new Date().toISOString()
      };
      localStorage.setItem('flutter.vestora_auth_is_logged_in', 'true');
      localStorage.setItem('flutter.vestora_auth_current_user_json', JSON.stringify(JSON.stringify(user)));
      window.location.reload();
    `);

    console.log('Waiting 5s for Main App boot...');
    await sleep(5000);

    // 1. Tab 0: Closet
    await client.screenshot(path.join(screenshotsDir, '02_tab_wardrobe.png'));

    // 2. Tab 1: Stylist (x=123, y=755 in 504x794 viewport)
    console.log('Clicking Tab 1: Stylist...');
    await client.click(150, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '03_tab_stylist.png'));

    // 3. Tab 2: Add Item (x=252, y=760)
    console.log('Clicking Tab 2: Add Item...');
    await client.click(252, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '04_tab_add_item.png'));

    // 4. Tab 3: Community (x=350, y=760)
    console.log('Clicking Tab 3: Community...');
    await client.click(350, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '05_tab_community.png'));

    // 5. Tab 4: Analytics (x=450, y=760)
    console.log('Clicking Tab 4: Analytics...');
    await client.click(450, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '06_tab_analytics.png'));

    // Go back to Stylist (x=150, y=760)
    console.log('Returning to Stylist...');
    await client.click(150, 760);
    await sleep(1200);

    // Click Virtual Fitting button in quick actions ("Приміряти", ~x=70, y=695)
    console.log('Opening Virtual Fitting...');
    await client.click(70, 695);
    await sleep(2500);
    await client.screenshot(path.join(screenshotsDir, '07_virtual_fitting.png'));

    // Back from Virtual Fitting
    await client.click(30, 45);
    await sleep(1200);

    // Stylist Menu
    console.log('Opening Stylist Menu...');
    await client.click(470, 45);
    await sleep(1000);
    await client.screenshot(path.join(screenshotsDir, '08_stylist_popup_menu.png'));

    // Click Capsule Matrix (item 2 in menu, ~x=350, y=140)
    await client.click(350, 140);
    await sleep(1800);
    await client.screenshot(path.join(screenshotsDir, '09_capsule_matrix.png'));

    // Back to Closet
    await client.click(30, 45);
    await sleep(1000);
    await client.click(50, 760);
    await sleep(1000);

    // Open Settings (x=470, y=45)
    console.log('Opening Settings Hub...');
    await client.click(470, 45);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '10_settings_hub.png'));

    console.log('\n--- CONSOLE AUDIT ---');
    console.log('Total logs:', client.consoleLogs.length);
    const issues = client.consoleLogs.filter(l => l.toLowerCase().includes('overflow') || l.toLowerCase().includes('error') || l.toLowerCase().includes('exception'));
    console.log('Issues found:', issues.length);
    issues.forEach(i => console.log(' >', i));

    client.close();
  } finally {
    chrome.kill();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

run();
