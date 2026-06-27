const { applicationDefault, cert, getApps, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');

function normalizePrivateKey(value) {
  return String(value || '').replace(/\\n/g, '\n');
}

function createDownloadImage(bucket) {
  return async function downloadImage(imagePath) {
    const file = bucket.file(imagePath);
    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size || 0);
    if (size > 10 * 1024 * 1024) throw new RangeError('Image is too large');
    const [bytes] = await file.download();
    return {
      bytes,
      mimeType: metadata.contentType || 'application/octet-stream',
    };
  };
}

function createFirebaseServices(config) {
  let services;
  function getServices() {
    if (services) return services;
    if (!config.storageBucket) {
      throw new Error('FIREBASE_STORAGE_BUCKET is required');
    }

    const credential = config.clientEmail && config.privateKey
      ? cert({
        projectId: config.projectId,
        clientEmail: config.clientEmail,
        privateKey: normalizePrivateKey(config.privateKey),
      })
      : applicationDefault();

    const app = getApps()[0] || initializeApp({
      credential,
      projectId: config.projectId || undefined,
      storageBucket: config.storageBucket,
    });
    const auth = getAuth(app);
    const bucket = getStorage(app).bucket(config.storageBucket);
    services = {
      verifyIdToken: (token) => auth.verifyIdToken(token),
      downloadImage: createDownloadImage(bucket),
    };
    return services;
  }

  return {
    verifyIdToken: (token) => getServices().verifyIdToken(token),
    downloadImage: (imagePath) => getServices().downloadImage(imagePath),
  };
}

module.exports = { createDownloadImage, createFirebaseServices, normalizePrivateKey };
