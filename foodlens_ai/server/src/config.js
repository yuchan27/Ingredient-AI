function parseInteger(value, fallback) {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function loadConfig(environment = process.env) {
  return {
    nodeEnv: environment.NODE_ENV || 'development',
    port: parseInteger(environment.PORT, 3000),
    allowedOrigins: (environment.CORS_ALLOWED_ORIGINS || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
    geminiApiKey: environment.GEMINI_API_KEY || '',
    firebase: {
      projectId: environment.FIREBASE_PROJECT_ID || '',
      clientEmail: environment.FIREBASE_CLIENT_EMAIL || '',
      privateKey: environment.FIREBASE_PRIVATE_KEY || '',
      storageBucket: environment.FIREBASE_STORAGE_BUCKET || '',
    },
    smtp: {
      host: environment.SMTP_HOST || 'smtp.gmail.com',
      port: parseInteger(environment.SMTP_PORT, 587),
      secure: String(environment.SMTP_SECURE).toLowerCase() === 'true',
      user: environment.SMTP_USER || '',
      password: environment.SMTP_PASS || '',
      fromName: environment.SMTP_FROM_NAME || 'FoodLens AI',
      fromEmail: environment.SMTP_FROM_EMAIL || environment.SMTP_USER || '',
    },
  };
}

module.exports = { loadConfig };
