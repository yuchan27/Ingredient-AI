class DailyQuotaExceededError extends Error {
  constructor({ limit, used }) {
    super('Daily AI quota exhausted');
    this.name = 'DailyQuotaExceededError';
    this.limit = limit;
    this.used = used;
  }
}

function quotaLimit(identity) {
  const provider = identity?.firebase?.sign_in_provider;
  return identity?.email_verified === true && provider !== 'anonymous' ? 50 : 5;
}

function utcDateKey(date) {
  return date.toISOString().slice(0, 10);
}

function createDailyQuotaService({ firestore, now = () => new Date() }) {
  async function reserve(identity) {
    if (!identity?.uid) throw new TypeError('Firebase uid is required');
    const date = utcDateKey(now());
    const limit = quotaLimit(identity);
    const key = `${date}_${identity.uid}`;
    const reference = firestore.collection('ai_usage').doc(key);

    const quota = await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      const used = snapshot.exists ? Number(snapshot.data()?.used || 0) : 0;
      if (used >= limit) throw new DailyQuotaExceededError({ limit, used });
      const nextUsed = used + 1;
      transaction.set(reference, {
        uid: identity.uid,
        date,
        limit,
        used: nextUsed,
        updatedAt: now().toISOString(),
      });
      return { limit, used: nextUsed, remaining: limit - nextUsed };
    });

    return { key, quota };
  }

  async function refund(reservation) {
    if (!reservation?.key) return;
    const reference = firestore.collection('ai_usage').doc(reservation.key);
    await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;
      const data = snapshot.data();
      transaction.set(reference, {
        ...data,
        used: Math.max(0, Number(data.used || 0) - 1),
        updatedAt: now().toISOString(),
      });
    });
  }

  return { reserve, refund };
}

module.exports = {
  DailyQuotaExceededError,
  createDailyQuotaService,
  quotaLimit,
  utcDateKey,
};
