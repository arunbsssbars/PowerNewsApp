const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const { PORT } = require('./config/constants');
const apiRoutes = require('./routes/apiRoutes');
const articleStore = require('./services/articleStore');
const { syncFeeds } = require('./services/rssService');

const app = express();

app.use(cors());
app.use(express.json());

// Mount API router
app.use('/api', apiRoutes);

// Root health probe — uptime monitors that check "/" get a 200 instead of 404
app.get('/', (req, res) => {
  res.json({ app: 'PowerNews', status: 'ok', healthEndpoint: '/api/health' });
});

// APK Download & Landing Page Helpers
function getAvailableApkPath() {
  const rootDir = path.join(__dirname, '..');
  const releasePath = path.join(rootDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (fs.existsSync(releasePath)) return { path: releasePath, filename: 'PowerNews.apk', type: 'Release' };
  const debugPath = path.join(rootDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');
  if (fs.existsSync(debugPath)) return { path: debugPath, filename: 'PowerNews-Debug.apk', type: 'Debug' };
  return null;
}

app.get('/download/app.apk', (req, res) => {
  const apkInfo = getAvailableApkPath();
  if (apkInfo) {
    res.setHeader('Content-Type', 'application/vnd.android.package-archive');
    res.setHeader('Content-Disposition', `attachment; filename="${apkInfo.filename}"`);
    res.sendFile(apkInfo.path);
  } else {
    res.status(404).json({ error: 'APK is currently compiling or not found. Please wait 30 seconds and refresh.' });
  }
});

app.get(['/download', '/apk'], (req, res) => {
  const apkInfo = getAvailableApkPath();
  const sizeMb = apkInfo ? (fs.statSync(apkInfo.path).size / (1024 * 1024)).toFixed(1) : null;

  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Download PowerNews App</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #0f172a;
      color: #f8fafc;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 16px;
      padding: 32px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 25px -5px rgba(0,0,0,0.5);
    }
    .icon {
      width: 68px;
      height: 68px;
      background: linear-gradient(135deg, #2563eb, #38bdf8);
      border-radius: 16px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 20px;
      font-size: 32px;
      color: white;
    }
    h1 { font-size: 24px; font-weight: 700; margin-bottom: 8px; color: #ffffff; }
    p.sub { font-size: 14px; color: #94a3b8; margin-bottom: 24px; line-height: 1.5; }
    .badge {
      display: inline-block;
      background: rgba(56, 189, 248, 0.15);
      color: #38bdf8;
      border: 1px solid rgba(56, 189, 248, 0.3);
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 24px;
    }
    .btn {
      display: block;
      width: 100%;
      background: #2563eb;
      color: white;
      text-decoration: none;
      padding: 14px;
      border-radius: 10px;
      font-size: 16px;
      font-weight: 600;
      transition: background 0.2s;
    }
    .btn:hover { background: #1d4ed8; }
    .meta { font-size: 12px; color: #64748b; margin-top: 18px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">⚡</div>
    <h1>PowerNews India</h1>
    <p class="sub">India's Premier Power, Grid & Renewable Energy Intelligence App</p>
    <div><span class="badge">Tailscale Connected: 100.98.130.99</span></div>
    <a href="/download/app.apk" class="btn" download>Download APK ${sizeMb ? `(${sizeMb} MB)` : ''}</a>
    <div class="meta">
      Built with Gemini 3.6 Flash & Content Grounding<br>
      IP: <code>100.98.130.99:3000</code>
    </div>
  </div>
</body>
</html>`);
});

// Periodic sync cron (every 20 mins)
cron.schedule('*/20 * * * *', async () => {
  const updated = await syncFeeds(articleStore.getArticles(), articleStore);
  articleStore.setArticles(updated);
});

// Server bootstrap
let server = null;

async function startServer() {
  server = app.listen(PORT, '0.0.0.0', async () => {
    console.log(`[PowerNews Aggregator] Running on port ${PORT} (0.0.0.0)`);
    const initialArticles = await syncFeeds(articleStore.getArticles(), articleStore);
    articleStore.setArticles(initialArticles);
  });
}

// Auto-start if run directly
if (require.main === module) {
  startServer();
}

module.exports = {
  app,
  startServer,
};
