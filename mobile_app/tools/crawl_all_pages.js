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
    await this.send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await sleep(40);
    await this.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await sleep(40);
    await this.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  }

  async screenshot(outPath) {
    const res = await this.send('Page.captureScreenshot', { format: 'png', quality: 90 });
    if (res && res.data) {
      fs.writeFileSync(outPath, Buffer.from(res.data, 'base64'));
      console.log(`Saved screenshot: ${path.basename(outPath)}`);
    }
  }

  close() {
    this.ws.close();
  }
}

async function run() {
  const screenshotsDir = path.join(__dirname, '..', 'screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  const chromePath = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
  const userDataDir = path.join(process.env.TEMP || 'C:\\Windows\\Temp', 'cdp_all_' + Date.now());

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

    console.log('1. Capturing 01_auth_screen...');
    await sleep(3500);
    await client.screenshot(path.join(screenshotsDir, '01_auth_screen.png'));

    // Authenticate
    console.log('Authenticating in localStorage...');
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

    await sleep(4500);

    // 2. Tab 0: Wardrobe
    console.log('2. Capturing 02_closet_screen...');
    await client.screenshot(path.join(screenshotsDir, '02_closet_screen.png'));

    // 3. Tab 1: Stylist
    console.log('3. Capturing 03_outfit_builder_screen...');
    await client.click(150, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '03_outfit_builder_screen.png'));

    // 4. Tab 2: Add Item
    console.log('4. Capturing 04_add_item_screen...');
    await client.click(252, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '04_add_item_screen.png'));

    // 5. Tab 3: Community
    console.log('5. Capturing 05_ootd_feed_screen...');
    await client.click(350, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '05_ootd_feed_screen.png'));

    // 6. Tab 4: Analytics
    console.log('6. Capturing 06_analytics_screen...');
    await client.click(450, 760);
    await sleep(1500);
    await client.screenshot(path.join(screenshotsDir, '06_analytics_screen.png'));

    // 7. Virtual Fitting Mirror (from Stylist -> "Приміряти")
    console.log('7. Opening Virtual Fitting...');
    await client.click(150, 760); // back to Stylist
    await sleep(1200);
    await client.click(70, 695); // click "Приміряти"
    await sleep(2500);
    await client.screenshot(path.join(screenshotsDir, '07_virtual_fitting_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // 8. Capsule Matrix 3x3 (from Closet -> quick pill "Матриця 3х3" at ~x=185, y=345)
    console.log('8. Opening Capsule Matrix 3x3...');
    await client.click(50, 760); // Tab 0 Closet
    await sleep(1200);
    await client.click(185, 345); // Capsule matrix pill
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '08_capsule_matrix_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // 9. Fabric Care (from Closet -> quick pill "Догляд & Бірки" at ~x=290, y=345)
    console.log('9. Opening Fabric Care Screen...');
    await client.click(290, 345);
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '09_fabric_care_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // 10. Purchase Advisor (from Closet -> banner "Плануєте покупку?" at ~x=250, y=305)
    console.log('10. Opening Purchase Advisor...');
    await client.click(250, 305);
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '10_purchase_advisor_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // 11. Settings Hub (from Closet -> Gear icon at ~x=425, y=28)
    console.log('11. Opening Settings Hub...');
    await client.click(425, 28);
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '11_settings_hub_screen.png'));

    // 12. Settings AI Engine (from Settings Hub -> AI Tile at ~x=250, y=340)
    console.log('12. Opening AI Settings...');
    await client.click(250, 340);
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '12_settings_ai_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);
    await client.click(20, 25); // back button from settings hub
    await sleep(1200);

    // 13. Editorial Story / Vogue Poster (from Stylist -> "Постер" at ~x=170, y=695)
    console.log('13. Opening Editorial Story / Vogue Poster...');
    await client.click(150, 760); // Tab 1 Stylist
    await sleep(1200);
    await client.click(170, 695); // "Постер"
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '13_editorial_story_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // 14. Outfit Calendar (from Stylist -> "Календар" at ~x=280, y=695)
    console.log('14. Opening Outfit Calendar...');
    await client.click(280, 695); // "Календар"
    await sleep(2000);
    await client.screenshot(path.join(screenshotsDir, '14_outfit_calendar_screen.png'));
    await client.click(20, 25); // back button
    await sleep(1200);

    // Console audit
    console.log('\n--- BROWSER CONSOLE AUDIT ---');
    console.log('Total console logs:', client.consoleLogs.length);
    const overflows = client.consoleLogs.filter(l => l.toLowerCase().includes('overflow'));
    const exceptions = client.consoleLogs.filter(l => l.includes('[EXCEPTION]') || l.toLowerCase().includes('unhandled'));
    console.log('Overflows:', overflows.length);
    if (overflows.length > 0) overflows.forEach(o => console.warn(o));
    console.log('Exceptions:', exceptions.length);
    if (exceptions.length > 0) exceptions.forEach(e => console.warn(e));

    client.close();
  } catch (err) {
    console.error('Crawler encountered error:', err);
  } finally {
    chrome.kill();
    try {
      fs.rmSync(userDataDir, { recursive: true, force: true });
    } catch (e) {}
  }
}

run();
