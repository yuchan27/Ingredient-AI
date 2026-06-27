const cors = require('cors');
const express = require('express');
const { rateLimit } = require('express-rate-limit');
const helmet = require('helmet');
const multer = require('multer');
const { z } = require('zod');

const analyzeRequestSchema = z.object({
  imagePath: z.string().min(1).max(512),
}).strict();

const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 1 },
  fileFilter: (_request, file, callback) => {
    callback(null, ['image/jpeg', 'image/png', 'image/webp'].includes(file.mimetype));
  },
});

function createCorsOptions(allowedOrigins) {
  return {
    credentials: false,
    methods: ['GET', 'POST'],
    allowedHeaders: ['Authorization', 'Content-Type'],
    origin(origin, callback) {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      callback(new Error('Origin not allowed'));
    },
  };
}

function createApp(dependencies) {
  const {
    nodeEnv,
    allowedOrigins = [],
    verifyIdToken,
    downloadImage,
    analyzeImage,
    sendTestEmail,
  } = dependencies;

  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors(createCorsOptions(allowedOrigins)));
  app.use(express.json({ limit: '32kb' }));

  app.get('/health', (_request, response) => {
    response.json({ ok: true });
  });

  if (nodeEnv === 'development') {
    app.post('/sendTestEmail', rateLimit({ windowMs: 60_000, limit: 3 }), async (_request, response, next) => {
      try {
        await sendTestEmail();
        response.json({ ok: true });
      } catch (error) {
        next(error);
      }
    });
  }

  app.post('/analyzeFoodImage', rateLimit({ windowMs: 60_000, limit: 10 }), async (request, response, next) => {
    const authorization = request.get('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      response.status(401).json({ error: 'Authentication required' });
      return;
    }

    let decodedToken;
    try {
      decodedToken = await verifyIdToken(authorization.slice(7));
    } catch (_error) {
      response.status(401).json({ error: 'Invalid authentication token' });
      return;
    }

    request.firebaseUser = decodedToken;
    next();
  }, imageUpload.single('image'), async (request, response, next) => {
    const decodedToken = request.firebaseUser;

    if (request.file) {
      try {
        const result = await analyzeImage({
          bytes: request.file.buffer,
          mimeType: request.file.mimetype,
        });
        response.json(result);
      } catch (error) {
        next(error);
      }
      return;
    }

    const parsed = analyzeRequestSchema.safeParse(request.body);
    if (!parsed.success) {
      response.status(400).json({ error: 'A valid imagePath is required' });
      return;
    }

    const ownedPrefix = `users/${decodedToken.uid}/`;
    if (!parsed.data.imagePath.startsWith(ownedPrefix)) {
      response.status(403).json({ error: 'Image path is not owned by the user' });
      return;
    }

    try {
      const image = await downloadImage(parsed.data.imagePath);
      const result = await analyzeImage(image);
      response.json(result);
    } catch (error) {
      next(error);
    }
  });

  app.use((_request, response) => {
    response.status(404).json({ error: 'Not found' });
  });

  app.use((error, _request, response, _next) => {
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      response.status(413).json({ error: 'Image is too large' });
      return;
    }
    if (nodeEnv !== 'test') {
      console.error('Request failed:', error?.name || 'Error');
    }
    response.status(500).json({ error: 'Internal server error' });
  });

  return app;
}

module.exports = { createApp };
