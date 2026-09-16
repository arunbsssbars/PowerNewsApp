const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
const express = require('express');
const cors = require('cors');
const cron = require('node-cron');
const helmet = require('helmet');
const { PORT } = require('./config/constants');
const apiRoutes = require('./routes/apiRoutes');
const articleStore = require('./services/articleStore');
const { syncFeeds } = require('./services/rssService');

const app = express();
app.use(express.json()); // Need JSON parsing for POST/PUT requests
app.use('/admin', express.static(path.join(__dirname, '..', 'public', 'admin')));

// Security Headers via Helmet
app.use(helmet({
  contentSecurityPolicy: false, // Allows inline CSS styling on the /download landing page
  crossOriginEmbedderPolicy: false,
}));

// Strict CORS Policy
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(s => s.trim().toLowerCase())
  : [];

const corsOptions = {
  origin: (origin, callback) => {
    // 1. Allow mobile clients, curl, and server-to-server requests (no Origin header)
    if (!origin) return callback(null, true);

    const lowerOrigin = origin.toLowerCase();

    // 2. Allow local development origins (localhost or 127.0.0.1 on any port)
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(lowerOrigin)) {
      return callback(null, true);
    }

    // 3. Allow explicitly configured origins in .env (e.g., your production web domain)
    if (allowedOrigins.includes(lowerOrigin)) {
      return callback(null, true);
    }

    // Block unknown browser origins
    console.warn(`[Security] Blocked unauthorized CORS request from origin: ${origin}`);
    return callback(null, false);
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-api-key'],
  credentials: true,
  maxAge: 86400,
};

app.use(cors(corsOptions));
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

// Google Play News App Compliance: Public Privacy Policy Endpoint
app.get('/privacy', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy - PowerNews India</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0D1117; color: #C9D1D9; max-width: 800px; margin: 0 auto; padding: 32px 20px; line-height: 1.6; }
    h1 { color: #58A6FF; font-size: 26px; border-bottom: 1px solid #30363D; padding-bottom: 12px; margin-bottom: 20px; }
    h2 { color: #79C0FF; font-size: 18px; margin-top: 24px; margin-bottom: 8px; }
    p, li { font-size: 14.5px; color: #8B949E; margin-bottom: 12px; }
    ul { padding-left: 24px; margin-bottom: 16px; }
    .card { background: #161B22; border: 1px solid #30363D; border-radius: 12px; padding: 20px; margin-top: 24px; }
    .contact-badge { color: #58A6FF; font-weight: 600; text-decoration: none; }
  </style>
</head>
<body>
  <h1>Privacy Policy for PowerNews India</h1>
  <p><strong>Effective Date:</strong> January 1, 2025 (Updated March 2025)</p>
  
  <p>PowerNews India ("we", "our", or "us") is dedicated to providing power sector executives, engineers, policymakers, and researchers with AI-grounded news briefings on India's electricity, grid, and renewable energy sectors. We respect your privacy and are committed to transparency.</p>

  <h2>1. Zero Personal Data Collection</h2>
  <p>PowerNews India does <strong>not require any account registration, user logins, or phone numbers</strong> to access news feeds. We do not collect, harvest, store, or sell any personally identifiable information (PII) such as your name, email address, contact list, or payment details.</p>

  <h2>2. Device Storage & Local Preferences</h2>
  <p>The application uses on-device local storage (SharedPreferences and local SQLite cache) solely to store:</p>
  <ul>
    <li>Your reading preferences (theme selection, summary font size, audio narration speed).</li>
    <li>Articles you have chosen to bookmark for offline access.</li>
  </ul>
  <p>This data stays entirely on your device and is never transmitted to our servers or any third-party analytics services.</p>

  <h2>3. Location Permission (Optional)</h2>
  <p>If granted, the location permission is used strictly on-device to highlight electricity and DISCOM updates from your immediate state (e.g., UP, Maharashtra, Karnataka). Your precise GPS location is <strong>never logged, transmitted, or shared</strong>.</p>

  <h2>4. Artificial Intelligence & Summaries</h2>
  <p>Our executive briefings and story highlights are generated by Google Gemini AI operating purely on public RSS feeds and press releases. No user personal queries, identities, or reader telemetry are passed into AI models.</p>

  <h2>5. Publisher Links & Fair Attribution</h2>
  <p>PowerNews India respects the intellectual property of original publishers (PIB, Mercom, PV Magazine, Financial Express, Economic Times, LiveMint, CERC/SERC). Every summary clearly displays the original source name and provides a direct link to the publisher's web page.</p>

  <div class="card">
    <h2 style="margin-top:0;">Contact Editorial Desk & Grievance Redressal</h2>
    <p>In accordance with Indian Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules and Google Play News Policy, publishers or users may contact our editorial team for queries, corrections, or feed removal requests:</p>
    <p><strong>Editorial Desk:</strong> PowerNews Energy Intelligence Cell<br>
    <strong>Email:</strong> <a class="contact-badge" href="mailto:editorial@powernews.app">editorial@powernews.app</a> / <a class="contact-badge" href="mailto:support@powernews.app">support@powernews.app</a><br>
    <strong>Location:</strong> New Delhi, India</p>
  </div>
</body>
</html>`);
});

// Editorial Desk & Publisher Grievance Redressal Endpoint
app.get('/editorial', (req, res) => {
  res.redirect('/privacy');
});

// Periodic sync cron (every 20 mins: at :00, :20, :40 of each hour)
cron.schedule('*/20 * * * *', async () => {
  console.log(`[Cron] ========================================================`);
  console.log(`[Cron] 🔄 20-minute periodic feed refresh started at ${new Date().toISOString()}`);
  console.log(`[Cron] ========================================================`);
  try {
    const updated = await syncFeeds(articleStore.getArticles(), articleStore);
    articleStore.setArticles(updated);
    console.log(`[Cron] ✅ Periodic feed refresh complete at ${new Date().toISOString()} (${updated.length} active articles)`);
  } catch (err) {
    console.error(`[Cron] ❌ Periodic feed refresh encountered an error:`, err.message);
  }
});

// Daily Firestore storage self-regulation cron (Runs every day at 03:30 AM)
cron.schedule('30 3 * * *', async () => {
  console.log(`[Cron] Running daily Firestore storage check (850 MB high-watermark check)...`);
  try {
    const { purgeOldestIfNearLimit } = require('./services/firestoreService');
    await purgeOldestIfNearLimit();
  } catch (err) {
    console.warn(`[Cron] Firestore storage check failed:`, err.message);
  }
});

// Server bootstrap
let server = null;

async function startServer() {
  server = app.listen(PORT, '0.0.0.0', async () => {
    console.log(`[PowerNews Aggregator] Running on port ${PORT} (0.0.0.0)`);
    const initialArticles = await syncFeeds(articleStore.getArticles(), articleStore);
    articleStore.setArticles(initialArticles);

    // Initial storage check 30 seconds after boot
    setTimeout(async () => {
      try {
        const { purgeOldestIfNearLimit } = require('./services/firestoreService');
        await purgeOldestIfNearLimit();
      } catch (_) {}
    }, 30000);
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
