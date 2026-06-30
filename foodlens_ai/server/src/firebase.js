const { applicationDefault, cert, getApps, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
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

function createFirebaseServices(config, dependencies = {}) {
  const getOrInitializeApp = dependencies.getOrInitializeApp || (() => {
    const credential = config.clientEmail && config.privateKey
      ? cert({
        projectId: config.projectId,
        clientEmail: config.clientEmail,
        privateKey: normalizePrivateKey(config.privateKey),
      })
      : applicationDefault();

    return getApps()[0] || initializeApp({
      credential,
      projectId: config.projectId || undefined,
      storageBucket: config.storageBucket || undefined,
    });
  });
  const authFor = dependencies.authFor || getAuth;
  const firestoreFor = dependencies.firestoreFor || getFirestore;
  const storageFor = dependencies.storageFor || (
    (app, bucketName) => getStorage(app).bucket(bucketName)
  );

  let coreServices;
  let downloadImage;
  function getCoreServices() {
    if (coreServices) return coreServices;
    const app = getOrInitializeApp();
    coreServices = {
      app,
      auth: authFor(app),
      firestore: firestoreFor(app),
    };
    return coreServices;
  }

  function getDownloadImage() {
    if (downloadImage) return downloadImage;
    if (!config.storageBucket) {
      throw new Error('FIREBASE_STORAGE_BUCKET is required for legacy image paths');
    }
    const services = getCoreServices();
    downloadImage = createDownloadImage(
      storageFor(services.app, config.storageBucket),
    );
    return downloadImage;
  }

  return {
    verifyIdToken: (token) => getCoreServices().auth.verifyIdToken(token),
    downloadImage: async (imagePath) => getDownloadImage()(imagePath),
    getFirestore: () => getCoreServices().firestore,
  };
}

module.exports = { createDownloadImage, createFirebaseServices, normalizePrivateKey };
