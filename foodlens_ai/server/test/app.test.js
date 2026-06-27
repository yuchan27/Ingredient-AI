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
  });
});

test('unknown routes return a JSON 404 without Express fingerprinting', async () => {
  const response = await request(createApp(dependencies())).get('/missing');
  assert.equal(response.status, 404);
  assert.deepEqual(response.body, { error: 'Not found' });
  assert.equal(response.headers['x-powered-by'], undefined);
});
