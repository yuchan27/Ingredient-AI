const assert = require('node:assert/strict');
const test = require('node:test');

const {
  DailyQuotaExceededError,
  createDailyQuotaService,
} = require('../src/quota');

function fakeFirestore() {
  const documents = new Map();
  return {
    documents,
    collection(name) {
      return {
        doc(id) {
          return { path: `${name}/${id}` };
        },
      };
    },
    async runTransaction(callback) {
      return callback({
        async get(reference) {
          const value = documents.get(reference.path);
          return { exists: value != null, data: () => value };
        },
        set(reference, value) {
          documents.set(reference.path, value);
        },
      });
    },
  };
}

test('anonymous users receive five analyses per UTC day', async () => {
  const firestore = fakeFirestore();
  const quota = createDailyQuotaService({
    firestore,
    now: () => new Date('2026-06-28T23:59:00Z'),
  });
  const identity = {
    uid: 'guest-1',
    firebase: { sign_in_provider: 'anonymous' },
  };

  let reservation;
  for (let index = 0; index < 5; index += 1) {
    reservation = await quota.reserve(identity);
  }

  assert.deepEqual(reservation.quota, { limit: 5, used: 5, remaining: 0 });
  await assert.rejects(
    quota.reserve(identity),
    (error) => error instanceof DailyQuotaExceededError
      && error.limit === 5
      && error.used === 5,
  );
});

test('verified Email users receive fifty analyses per UTC day', async () => {
  const quota = createDailyQuotaService({
    firestore: fakeFirestore(),
    now: () => new Date('2026-06-28T12:00:00Z'),
  });
  const identity = {
    uid: 'member-1',
    email_verified: true,
    firebase: { sign_in_provider: 'password' },
  };

  let reservation;
  for (let index = 0; index < 50; index += 1) {
    reservation = await quota.reserve(identity);
  }

  assert.equal(reservation.quota.limit, 50);
  assert.equal(reservation.quota.remaining, 0);
  await assert.rejects(quota.reserve(identity), DailyQuotaExceededError);
});

test('quota resets on a new UTC date and can refund failed analysis', async () => {
  const firestore = fakeFirestore();
  let current = new Date('2026-06-28T23:59:00Z');
  const quota = createDailyQuotaService({
    firestore,
    now: () => current,
  });
  const identity = {
    uid: 'guest-2',
    firebase: { sign_in_provider: 'anonymous' },
  };

  const first = await quota.reserve(identity);
  await quota.refund(first);
  const afterRefund = await quota.reserve(identity);
  assert.equal(afterRefund.quota.used, 1);

  current = new Date('2026-06-29T00:01:00Z');
  const nextDay = await quota.reserve(identity);
  assert.equal(nextDay.quota.used, 1);
  assert.equal(firestore.documents.size, 2);
});
