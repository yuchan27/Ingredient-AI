require('dotenv').config({ quiet: true });

const { createApp } = require('./app');
const { loadConfig } = require('./config');
const { createFirebaseServices } = require('./firebase');
const { createGeminiFoodAnalyzer } = require('./gemini');
const { createNodemailerTestMailer } = require('./mailer');
const { createDailyQuotaService } = require('./quota');

const config = loadConfig();
const firebase = createFirebaseServices(config.firebase);
const quota = createDailyQuotaService({ firestore: firebase.getFirestore() });

const app = createApp({
  nodeEnv: config.nodeEnv,
  allowedOrigins: config.allowedOrigins,
  verifyIdToken: firebase.verifyIdToken,
  downloadImage: firebase.downloadImage,
  analyzeImage: config.geminiApiKey
    ? createGeminiFoodAnalyzer(config.geminiApiKey)
    : async () => { throw new Error('GEMINI_API_KEY is required'); },
  sendTestEmail: createNodemailerTestMailer(config.smtp),
  quota,
});

if (!process.env.VERCEL) {
  const server = app.listen(config.port, '0.0.0.0', () => {
    console.log(`FoodLens AI server listening on port ${config.port}`);
  });

  server.requestTimeout = 30_000;
  server.headersTimeout = 35_000;
  server.on('error', (error) => {
    console.error('Server error:', error?.name || 'Error');
  });
}

module.exports = app;
