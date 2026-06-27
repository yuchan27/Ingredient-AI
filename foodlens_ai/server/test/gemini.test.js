const assert = require('node:assert/strict');
const test = require('node:test');

const {
  createFoodAnalyzer,
  normalizeFoodAnalysis,
  parseJsonResponse,
} = require('../src/gemini');

test('parseJsonResponse accepts fenced JSON', () => {
  const result = parseJsonResponse('```json\n{"foodName":"沙拉","calories":120}\n```');
  assert.equal(result.foodName, '沙拉');
  assert.equal(result.calories, 120);
});

test('normalizeFoodAnalysis clamps and fills the fixed response shape', () => {
  assert.deepEqual(normalizeFoodAnalysis({
    foodName: '  雞排  ',
    calories: '650',
    protein: -3,
    fat: 25.555,
    carbs: 68,
    confidence: 4,
  }), {
    foodName: '雞排',
    calories: 650,
    protein: 0,
    fat: 25.6,
    carbs: 68,
    confidence: 1,
    notes: '',
  });
});

test('food analyzer uses Gemini 2.5 Flash first', async () => {
  const calls = [];
  const analyzer = createFoodAnalyzer({
    generateContent: async ({ model }) => {
      calls.push(model);
      return { text: '{"foodName":"牛肉麵","calories":520,"protein":28,"fat":16,"carbs":64,"confidence":0.91,"notes":"估算"}' };
    },
  });

  const result = await analyzer({ bytes: Buffer.from('image'), mimeType: 'image/jpeg' });
  assert.equal(result.foodName, '牛肉麵');
  assert.deepEqual(calls, ['gemini-2.5-flash']);
});

test('food analyzer falls back to Gemma when the primary model fails', async () => {
  const calls = [];
  const analyzer = createFoodAnalyzer({
    generateContent: async ({ model }) => {
      calls.push(model);
      if (model === 'gemini-2.5-flash') throw new Error('primary unavailable');
      return { text: '{"foodName":"飯糰","calories":310,"protein":9,"fat":4,"carbs":59,"confidence":0.72,"notes":"fallback"}' };
    },
  });

  const result = await analyzer({ bytes: Buffer.from('image'), mimeType: 'image/png' });
  assert.equal(result.foodName, '飯糰');
  assert.deepEqual(calls, ['gemini-2.5-flash', 'gemma-4-26b-a4b-it']);
});

test('food analyzer rejects unsupported image types', async () => {
  const analyzer = createFoodAnalyzer({ generateContent: async () => ({ text: '{}' }) });
  await assert.rejects(
    analyzer({ bytes: Buffer.from('text'), mimeType: 'text/plain' }),
    /Unsupported image type/,
  );
});

test('food analyzer rejects images larger than 10 MB', async () => {
  const analyzer = createFoodAnalyzer({ generateContent: async () => ({ text: '{}' }) });
  await assert.rejects(
    analyzer({ bytes: Buffer.alloc(10 * 1024 * 1024 + 1), mimeType: 'image/jpeg' }),
    /Image is too large/,
  );
});
