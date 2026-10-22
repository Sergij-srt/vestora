const http = require('http');
const { spawn } = require('child_process');

async function test() {
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const userDataDir = 'C:\\Windows\\Temp\\cdp_net_closet';
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--user-data-dir=' + userDataDir,
    '--window-size=412,890',
    'http://127.0.0.1:8080'
  ]);

  await new Promise(r => setTimeout(r, 2000));
  const pages = await new Promise((res, rej) => http.get('http://127.0.0.1:9222/json', r => {
    let d = ''; r.on('data', c => d += c); r.on('end', () => res(JSON.parse(d)));
  }));
  const wsUrl = pages[0].webSocketDebuggerUrl;
  const ws = new WebSocket(wsUrl);
  await new Promise(r => ws.onopen = r);

  let id = 1;
  const send = (m, p={}) => new Promise(r => {
    const cur = id++;
    const h = (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id === cur) { ws.removeEventListener('message', h); r(msg.result); }
    };
    ws.addEventListener('message', h);
    ws.send(JSON.stringify({id: cur, method: m, params: p}));
  });

  ws.addEventListener('message', ev => {
    const msg = JSON.parse(ev.data);
    if (msg.method === 'Network.responseReceived') {
      const r = msg.params.response;
      if (r.url.includes('unsplash') || r.status >= 400) {
        console.log('NETWORK RESP:', r.status, r.url.substring(0, 60));
      }
    } else if (msg.method === 'Network.loadingFailed') {
      console.log('NETWORK FAIL:', msg.params.errorText, msg.params.type);
    } else if (msg.method === 'Runtime.consoleAPICalled') {
      console.log('CONSOLE:', msg.params.args.map(a => a.value || JSON.stringify(a)).join(' '));
    }
  });

  await send('Page.enable');
  await send('Runtime.enable');
  await send('Network.enable');

  const expr = 'localStorage.setItem("flutter.vestora_auth_is_logged_in", "true");' +
    'localStorage.setItem("flutter.vestora_auth_current_user_json", JSON.stringify(JSON.stringify({id:"usr_1",email:"test@vestora.app",displayName:"Test",method:"guest",createdAt:new Date().toISOString()})));' +
    'window.location.reload();';

  await send('Runtime.evaluate', { expression: expr });

  await new Promise(r => setTimeout(r, 6000));
  ws.close();
  chrome.kill();
}
test();
