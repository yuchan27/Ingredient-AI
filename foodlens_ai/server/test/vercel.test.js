const assert = require('node:assert/strict');
const test = require('node:test');
const packageJson = require('../package.json');

test('cloud runtime stays on Node 22 LTS', () => {
  assert.equal(packageJson.engines.node, '22.x');
});

test('Firebase Admin stays on the CommonJS-compatible serverless release', () => {
  assert.equal(packageJson.dependencies['firebase-admin'], '14.1.0');
});

test('Vercel entry exports the Express application without opening a listener', () => {
  const previous = {
    nodeEnv: process.env.NODE_ENV,
    vercel: process.env.VERCEL,
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  };
  process.env.NODE_ENV = 'test';
  process.env.VERCEL = '1';
  process.env.FIREBASE_PROJECT_ID = 'test-project';
  process.env.FIREBASE_STORAGE_BUCKET = 'test-bucket';

  try {
    const app = require('../api/index');
    assert.equal(typeof app, 'function');
    assert.equal(typeof app.listen, 'function');
  } finally {
    process.env.NODE_ENV = previous.nodeEnv;
    process.env.VERCEL = previous.vercel;
    process.env.FIREBASE_PROJECT_ID = previous.projectId;
    process.env.FIREBASE_STORAGE_BUCKET = previous.storageBucket;
  }
});
