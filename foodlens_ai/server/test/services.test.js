const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createDownloadImage,
  createFirebaseServices,
  normalizePrivateKey,
} = require('../src/firebase');
const { createTestMailer } = require('../src/mailer');
const { loadConfig } = require('../src/config');

test('loadConfig parses booleans, ports, and CORS origins', () => {
  const config = loadConfig({
    NODE_ENV: 'development',
    PORT: '3100',
    SMTP_PORT: '587',
    SMTP_SECURE: 'false',
    CORS_ALLOWED_ORIGINS: 'http://localhost:5173, https://app.example.com ',
  });
  assert.equal(config.port, 3100);
  assert.equal(config.smtp.port, 587);
  assert.equal(config.smtp.secure, false);
  assert.deepEqual(config.allowedOrigins, ['http://localhost:5173', 'https://app.example.com']);
});

test('normalizePrivateKey restores escaped newlines', () => {
  assert.equal(normalizePrivateKey('line1\\nline2'), 'line1\nline2');
});

test('createDownloadImage reads bytes and content type from Storage', async () => {
  let requestedPath;
  const bucket = {
    file(path) {
      requestedPath = path;
      return {
        async getMetadata() {
          return [{ contentType: 'image/webp', size: '4' }];
        },
        async download() {
          return [Buffer.from('data')];
        },
      };
    },
  };

  const downloadImage = createDownloadImage(bucket);
  const result = await downloadImage('users/u1/food_images/r1.jpg');

  assert.equal(requestedPath, 'users/u1/food_images/r1.jpg');
  assert.equal(result.mimeType, 'image/webp');
  assert.equal(result.bytes.toString(), 'data');
});

test('Firestore starts without a Storage bucket and Storage stays unavailable', async () => {
  const firestore = { name: 'firestore' };
  let storageRequested = false;
  const services = createFirebaseServices(
    { projectId: 'test-project', storageBucket: '' },
    {
      getOrInitializeApp: () => ({ name: 'test-app' }),
      authFor: () => ({ verifyIdToken: async () => ({ uid: 'u1' }) }),
      firestoreFor: () => firestore,
      storageFor: () => {
        storageRequested = true;
        throw new Error('Storage must not initialize without a bucket');
      },
    },
  );

  assert.equal(services.getFirestore(), firestore);
  assert.equal(storageRequested, false);
  await assert.rejects(
    services.downloadImage('users/u1/food_images/r1.jpg'),
    /FIREBASE_STORAGE_BUCKET is required/,
  );
  assert.equal(storageRequested, false);
});

test('test mailer sends only to the configured account with a named sender', async () => {
  let message;
  const mailer = createTestMailer({
    smtpUser: 'owner@example.com',
    fromName: 'FoodLens AI',
    fromEmail: 'sender@example.com',
    transport: {
      async sendMail(value) {
        message = value;
        return { messageId: 'm1' };
      },
    },
  });

  const result = await mailer();
  assert.equal(result.messageId, 'm1');
  assert.equal(message.to, 'owner@example.com');
  assert.equal(message.from, '"FoodLens AI" <sender@example.com>');
  assert.match(message.subject, /FoodLens AI/);
});
