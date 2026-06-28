const assert = require('node:assert/strict');
const test = require('node:test');
const request = require('supertest');

const { createApp } = require('../src/app');

function dependencies(overrides = {}) {
  return {
    nodeEnv: 'test',
    allowedOrigins: [],
    verifyIdToken: async (token) => {
      if (token === 'valid-token') return { uid: 'user-123' };
      throw new Error('invalid token');
    },
    downloadImage: async () => ({
      bytes: Buffer.from('fake-image'),
      mimeType: 'image/jpeg',
    }),
    analyzeImage: async () => ({
      foodName: '雞排便當',
      calories: 780,
      protein: 35,
      fat: 28,
      carbs: 92,
      confidence: 0.88,
      notes: '估算值，請依實際份量調整。',
    }),
    quota: {
      reserve: async () => ({
        key: '2026-06-28_user-123',
        quota: { limit: 50, used: 1, remaining: 49 },
      }),
      refund: async () => {},
    },
    sendTestEmail: async () => ({ messageId: 'mail-1' }),
    ...overrides,
  };
}

test('GET /health returns ok', async () => {
  const response = await request(createApp(dependencies())).get('/health');
  assert.equal(response.status, 200);
  assert.deepEqual(response.body, { ok: true });
});

test('POST /sendTestEmail is hidden outside development', async () => {
  const response = await request(createApp(dependencies()))
    .post('/sendTestEmail')
    .send({});
  assert.equal(response.status, 404);
  assert.deepEqual(response.body, { error: 'Not found' });
});

test('POST /sendTestEmail sends only in development', async () => {
  let sent = false;
  const app = createApp(dependencies({
    nodeEnv: 'development',
    sendTestEmail: async () => {
      sent = true;
      return { messageId: 'mail-1' };
    },
  }));

  const response = await request(app).post('/sendTestEmail').send({});
  assert.equal(response.status, 200);
  assert.equal(sent, true);
  assert.deepEqual(response.body, { ok: true });
});

test('POST /analyzeFoodImage rejects requests without a bearer token', async () => {
  const response = await request(createApp(dependencies()))
    .post('/analyzeFoodImage')
    .send({ imagePath: 'users/user-123/food_images/a.jpg' });
  assert.equal(response.status, 401);
  assert.deepEqual(response.body, { error: 'Authentication required' });
});

test('POST /analyzeFoodImage rejects invalid tokens', async () => {
  const response = await request(createApp(dependencies()))
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer invalid-token')
    .send({ imagePath: 'users/user-123/food_images/a.jpg' });
  assert.equal(response.status, 401);
  assert.deepEqual(response.body, { error: 'Invalid authentication token' });
});

test('POST /analyzeFoodImage analyzes an authenticated multipart image', async () => {
  let analyzedImage;
  const app = createApp(dependencies({
    analyzeImage: async (image) => {
      analyzedImage = image;
      return {
        foodName: '雞胸便當',
        calories: 520,
        protein: 42,
        fat: 14,
        carbs: 56,
        confidence: 0.91,
        notes: '圖片直接上傳分析',
      };
    },
  }));

  const response = await request(app)
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .attach('image', Buffer.from('fake-image'), {
      filename: 'meal.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 200);
  assert.equal(analyzedImage.mimeType, 'image/jpeg');
  assert.equal(analyzedImage.bytes.toString(), 'fake-image');
  assert.equal(response.body.foodName, '雞胸便當');
  assert.deepEqual(response.body.quota, { limit: 50, used: 1, remaining: 49 });
});

test('POST /analyzeFoodImage returns quota details when the daily limit is exhausted', async () => {
  const error = new Error('Daily AI quota exhausted');
  error.name = 'DailyQuotaExceededError';
  error.limit = 5;
  error.used = 5;
  const app = createApp(dependencies({
    quota: {
      reserve: async () => { throw error; },
      refund: async () => {},
    },
  }));

  const response = await request(app)
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .attach('image', Buffer.from('fake-image'), {
      filename: 'meal.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 429);
  assert.deepEqual(response.body, {
    error: '今天的 AI 次數已用完，請明天再試。',
    quota: { limit: 5, used: 5, remaining: 0 },
  });
});

test('POST /analyzeFoodImage refunds quota when analysis fails', async () => {
  let refunded;
  const reservation = {
    key: '2026-06-28_user-123',
    quota: { limit: 50, used: 1, remaining: 49 },
  };
  const app = createApp(dependencies({
    analyzeImage: async () => { throw new Error('Gemini unavailable'); },
    quota: {
      reserve: async () => reservation,
      refund: async (value) => { refunded = value; },
    },
  }));

  const response = await request(app)
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .attach('image', Buffer.from('fake-image'), {
      filename: 'meal.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 500);
  assert.equal(refunded, reservation);
});

test('POST /analyzeFoodImage rejects images larger than 10 MB', async () => {
  const response = await request(createApp(dependencies()))
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .attach('image', Buffer.alloc(10 * 1024 * 1024 + 1), {
      filename: 'oversized.jpg',
      contentType: 'image/jpeg',
    });

  assert.equal(response.status, 413);
  assert.deepEqual(response.body, { error: 'Image is too large' });
});

test('POST /analyzeFoodImage rejects another users storage path', async () => {
  const response = await request(createApp(dependencies()))
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .send({ imagePath: 'users/other-user/food_images/a.jpg' });
  assert.equal(response.status, 403);
  assert.deepEqual(response.body, { error: 'Image path is not owned by the user' });
});

test('POST /analyzeFoodImage downloads and analyzes the owned image', async () => {
  let downloadedPath;
  const app = createApp(dependencies({
    downloadImage: async (imagePath) => {
      downloadedPath = imagePath;
      return { bytes: Buffer.from('image'), mimeType: 'image/png' };
    },
  }));

  const response = await request(app)
    .post('/analyzeFoodImage')
    .set('Authorization', 'Bearer valid-token')
    .send({ imagePath: 'users/user-123/food_images/record-1.jpg' });

  assert.equal(response.status, 200);
  assert.equal(downloadedPath, 'users/user-123/food_images/record-1.jpg');
  assert.deepEqual(response.body, {
    foodName: '雞排便當',
    calories: 780,
    protein: 35,
    fat: 28,
    carbs: 92,
    confidence: 0.88,
    notes: '估算值，請依實際份量調整。',
    quota: { limit: 50, used: 1, remaining: 49 },
  });
});

test('unknown routes return a JSON 404 without Express fingerprinting', async () => {
  const response = await request(createApp(dependencies())).get('/missing');
  assert.equal(response.status, 404);
  assert.deepEqual(response.body, { error: 'Not found' });
  assert.equal(response.headers['x-powered-by'], undefined);
});
