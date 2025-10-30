const express = require('express');
const cors = require('cors');
const multer = require('multer');
const archiver = require('archiver');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// GET /health
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// GET /status
app.get('/status', async (req, res) => {
  const results = {
    backend: { ok: true },
    ollama: { ok: false },
    frontend: { ok: false },
    nginx: { ok: false },
    time: new Date().toISOString()
  };

  try {
    const r = await axios.get('http://ollama:11434/api/version', { timeout: 1000 });
    results.ollama.ok = r.status === 200;
    results.ollama.version = r.data;
  } catch (_) {}

  try {
    const r = await axios.get('http://frontend:3000', { timeout: 1000 });
    results.frontend.ok = r.status >= 200 && r.status < 500;
  } catch (_) {}

  try {
    const r = await axios.get('http://nginx', { timeout: 1000 });
    results.nginx.ok = r.status >= 200 && r.status < 500;
  } catch (_) {}

  res.json(results);
});

// POST /generate
app.post('/generate', async (req, res) => {
  const { prompt } = req.body;
  // TODO: Send prompt to Ollama model (localhost:11434)
  // For now, create a dummy zip with README
  const tmpDir = path.join(__dirname, '../../shared-outputs', Date.now().toString());
  fs.mkdirSync(tmpDir, { recursive: true });
  fs.writeFileSync(path.join(tmpDir, 'README.txt'), `Prompt: ${prompt}\nThis is a placeholder.`);
  const zipName = `output.zip`;
  const zipPath = path.join(tmpDir, zipName);
  const output = fs.createWriteStream(zipPath);
  const archive = archiver('zip', { zlib: { level: 9 } });

  output.on('close', () => {
    res.download(zipPath, zipName, err => {
      if (err) res.status(500).send('Zip error');
      fs.rmSync(tmpDir, { recursive: true, force: true });
    });
  });
  archive.pipe(output);
  archive.file(path.join(tmpDir, 'README.txt'), { name: 'README.txt' });
  archive.finalize();
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
