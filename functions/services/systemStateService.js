const fs = require('fs');
const path = require('path');

const STATE_FILE = path.join(__dirname, '..', '.server_lifecycle.json');
const bootDate = new Date();
const bootTimestamp = bootDate.toISOString();

let lastExitReason = 'Cold Boot / Initial Deployment';
let restartCount = 1;
let previousExitTime = null;

// 1. Read previous lifecycle state if available
try {
  if (fs.existsSync(STATE_FILE)) {
    const raw = fs.readFileSync(STATE_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    if (parsed) {
      if (parsed.lastExitReason && parsed.lastExitReason !== 'Running') {
        lastExitReason = parsed.lastExitReason;
      } else {
        lastExitReason = 'Code change reload / Watch restart';
      }
      restartCount = (parsed.restartCount || 0) + 1;
      previousExitTime = parsed.lastExitTime || null;
    }
  }
} catch (_) {}

// 2. Persist current boot state
function persistState(reason) {
  try {
    const data = {
      lastBootTime: bootTimestamp,
      restartCount,
      lastExitReason: reason || lastExitReason,
      lastExitTime: new Date().toISOString(),
      nodeVersion: process.version,
      platform: process.platform,
    };
    fs.writeFileSync(STATE_FILE, JSON.stringify(data, null, 2));
  } catch (_) {}
}

// Initial write with current boot info
persistState(lastExitReason);

// 3. Register lifecycle hooks to record exit reasons on shutdown
const handleExitSignal = (signal, reason) => {
  persistState(reason);
  process.exit(0);
};

process.once('SIGINT', () => handleExitSignal('SIGINT', 'Manual Operator Interruption (Ctrl+C / SIGINT)'));
process.once('SIGTERM', () => handleExitSignal('SIGTERM', 'Code change reload / Container rotation (SIGTERM)'));
process.once('SIGHUP', () => handleExitSignal('SIGHUP', 'Terminal / Parent Process Disconnected (SIGHUP)'));

process.on('uncaughtException', (err) => {
  persistState(`Crash Guard Recovery: ${err.message}`);
});

function formatUptime(seconds) {
  const sec = Math.floor(seconds);
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;

  const parts = [];
  if (d > 0) parts.push(`${d}d`);
  if (h > 0) parts.push(`${h}h`);
  if (m > 0) parts.push(`${m}m`);
  parts.push(`${s}s`);
  return parts.length > 0 ? parts.join(' ') : '0s';
}

function getReadableDate(isoString) {
  if (!isoString) return null;
  const d = new Date(isoString);
  return d.toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    dateStyle: 'medium',
    timeStyle: 'medium',
    hour12: true,
  }) + ' IST';
}

function getSystemLifecycle() {
  const uptimeSec = Math.floor(process.uptime());
  const isOffline = process.env.USE_CLOUD_FIRESTORE === 'false' || process.argv.includes('--offline');

  return {
    uptimeSeconds: uptimeSec,
    uptimeFormatted: formatUptime(uptimeSec),
    serverStartedAt: getReadableDate(bootTimestamp),
    serverStartedAtIso: bootTimestamp,
    lastRestartReason: lastExitReason,
    previousExitTime: getReadableDate(previousExitTime),
    previousExitTimeIso: previousExitTime,
    restartCount,
    databaseMode: isOffline ? 'Offline (Local In-Memory Zero-Quota)' : 'Cloud Firestore (Production)',
  };
}

module.exports = {
  getSystemLifecycle,
  bootTimestamp,
};
