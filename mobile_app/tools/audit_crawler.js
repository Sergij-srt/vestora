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
    this.events = [];
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
    await sleep(50);
    await this.send('Input.dispatchMouseEvent', {
      type: 'mousePressed',
      x,
      y,
      button: 'left',
      clickCount: 1
    });
    await sleep(50);
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

async function main() {
  const screenshotsDir = path.join(__dirname, '..', 'screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  const chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
  const userDataDir = path.join(process.env.TEMP || 'C:\\Windows\\Temp', 'vestora_cdp_' + Date.now());

  console.log('Launching Headless Chrome...');
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--user-data-dir=' + userDataDir,
    '--window-size=412,890',
    '--hide-scrollbars',
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

    if (!wsUrl) {
      throw new Error('Could not find Chrome page target');
    }

    console.log('Connecting CDP to:', wsUrl);
    const client = new CdpClient(wsUrl);
    await client.ready();
    await client.send('Page.enable');
    await client.send('Runtime.enable');

    console.log('Waiting for Flutter app initialization...');
    await sleep(4000);

    // 1. Capture Auth Screen
    await client.screenshot(path.join(screenshotsDir, '01_auth_screen.png'));

    // Authenticate as Guest in localStorage
    console.log('Authenticating as Demo Guest in localStorage...');
    await client.eval(`
      localStorage.setItem('flutter.vestora_auth_is_logged_in', 'true');
      localStorage.setItem('flutter.vestora_auth_current_user_json', JSON.stringify({
        id: 'usr_guest_demo',
        email: 'guest@vestora.app',
        displayName: 'Олена (Гість)',
        method: 'guest',
        createdAt: new Date().toISOString()
      }));
      window.location.reload();
    `);

    console.log('Waiting for Main Screen reload...');
    await sleep(4500);

    // 2. Tab 0: Wardrobe (ClosetScreen)
    await client.screenshot(path.join(screenshotsDir, '02_tab_wardrobe.png'));

    // 3. Tab 1: AI Stylist (x=123, y=855)
    console.log('Navigating to Tab 1 (Stylist)...');
    await client.click(123, 855);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '03_tab_stylist.png'));

    // 4. Tab 2: Add Item (x=206, y=855)
    console.log('Navigating to Tab 2 (Add Item)...');
    await client.click(206, 855);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '04_tab_add_item.png'));

    // 5. Tab 3: Community / OOTD (x=288, y=855)
    console.log('Navigating to Tab 3 (Community)...');
    await client.click(288, 855);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '05_tab_community.png'));

    // 6. Tab 4: Analytics (x=370, y=855)
    console.log('Navigating to Tab 4 (Analytics)...');
    await client.click(370, 855);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '06_tab_analytics.png'));

    // Return to Tab 1 (Stylist) to test Virtual Fitting and tools
    console.log('Returning to Tab 1 (Stylist)...');
    await client.click(123, 855);
    await sleep(1500);

    // Click Virtual Fitting button in quick actions ("Приміряти", ~x=55, y=785)
    console.log('Opening Virtual Fitting...');
    await client.click(55, 785);
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '07_virtual_fitting.png'));

    // Close / back from Virtual Fitting (Back arrow at x=25, y=45)
    console.log('Back from Virtual Fitting...');
    await client.click(25, 45);
    await sleep(1200);

    // Open Stylist Overflow Menu (x=390, y=45)
    console.log('Opening Stylist Menu...');
    await client.click(390, 45);
    await sleep(800);
    await client.screenshot(path.join(screenshotsDir, '08_stylist_popup_menu.png'));

    // Click Capsule Matrix (item 2 in popup menu, ~x=280, y=140)
    console.log('Clicking Capsule Matrix...');
    await client.click(280, 140);
    await sleep(1800);
    await client.screenshot(path.join(screenshotsDir, '09_capsule_matrix.png'));
    await client.click(25, 45); // back
    await sleep(1000);

    // Go to Tab 0 (Closet)
    await client.click(42, 855);
    await sleep(1200);

    // Click Settings Gear on ClosetScreen (x=385, y=45)
    console.log('Opening Settings Hub...');
    await client.click(385, 45);
    await sleep(1800);
    await client.screenshot(path.join(screenshotsDir, '10_settings_hub.png'));

    // Check console logs
    console.log('\n--- BROWSER CONSOLE AUDIT ---');
    const overflows = client.consoleLogs.filter(l => l.toLowerCase().includes('overflow'));
    const exceptions = client.consoleLogs.filter(l => l.includes('[EXCEPTION]') || l.toLowerCase().includes('unhandled'));
    
    console.log(`Total logs: ${client.consoleLogs.length}`);
    console.log(`Overflow errors: ${overflows.length}`);
    if (overflows.length > 0) {
      console.warn('OVERFLOWS DETECTED:');
      overflows.forEach(o => console.warn(o));
    }
    console.log(`Exceptions: ${exceptions.length}`);
    if (exceptions.length > 0) {
      console.warn('EXCEPTIONS DETECTED:');
      exceptions.forEach(e => console.warn(e));
    }

    client.close();
  } catch (err) {
    console.error('Audit failed with error:', err);
  } finally {
    chrome.kill();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

main();
