const { GoogleGenAI } = require('@google/genai');

const PRIMARY_MODEL = 'gemini-2.5-flash';
const FALLBACK_MODEL = 'gemma-4-26b-a4b-it';
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const ALLOWED_IMAGE_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

const ANALYSIS_PROMPT = `
你是食品營養分析助理。請從圖片辨識主要食物與份量，估算整份熱量與三大營養素。
只能回傳單一 JSON 物件，不要 Markdown，不要額外文字。
欄位必須為：foodName(string), calories(number), protein(number), fat(number), carbs(number), confidence(0到1), notes(string)。
數值為整份估計，營養素單位為公克，熱量單位為 kcal。無法判斷時仍回傳完整欄位，並在 notes 說明不確定性。
`.trim();

function parseJsonResponse(text) {
  const cleaned = String(text ?? '')
    .trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/, '');
  return JSON.parse(cleaned);
}

function finiteNumber(value, fallback = 0) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function roundedNonNegative(value) {
  return Math.round(Math.max(0, finiteNumber(value)) * 10) / 10;
}

function normalizeFoodAnalysis(value) {
  return {
    foodName: String(value?.foodName ?? '未知食物').trim().slice(0, 120) || '未知食物',
    calories: roundedNonNegative(value?.calories),
    protein: roundedNonNegative(value?.protein),
    fat: roundedNonNegative(value?.fat),
    carbs: roundedNonNegative(value?.carbs),
    confidence: Math.round(Math.min(1, Math.max(0, finiteNumber(value?.confidence))) * 100) / 100,
    notes: String(value?.notes ?? '').trim().slice(0, 500),
  };
}

function validateImage(image) {
  if (!image || !Buffer.isBuffer(image.bytes)) {
    throw new TypeError('Image bytes are required');
  }
  if (!ALLOWED_IMAGE_TYPES.has(image.mimeType)) {
    throw new TypeError('Unsupported image type');
  }
  if (image.bytes.length > MAX_IMAGE_BYTES) {
    throw new RangeError('Image is too large');
  }
}

function createFoodAnalyzer({ generateContent }) {
  return async function analyzeFoodImage(image) {
    validateImage(image);
    const request = {
      contents: [
        { text: ANALYSIS_PROMPT },
        {
          inlineData: {
            mimeType: image.mimeType,
            data: image.bytes.toString('base64'),
          },
        },
      ],
      config: {
        temperature: 0.1,
        responseMimeType: 'application/json',
      },
    };

    let lastError;
    for (const model of [PRIMARY_MODEL, FALLBACK_MODEL]) {
      try {
        const response = await generateContent({ model, ...request });
        return normalizeFoodAnalysis(parseJsonResponse(response.text));
      } catch (error) {
        lastError = error;
      }
    }
    throw new Error('Food analysis failed', { cause: lastError });
  };
}

function createGeminiFoodAnalyzer(apiKey) {
  if (!apiKey) throw new Error('GEMINI_API_KEY is required');
  const client = new GoogleGenAI({ apiKey });
  return createFoodAnalyzer({
    generateContent: (request) => client.models.generateContent(request),
  });
}

module.exports = {
  FALLBACK_MODEL,
  PRIMARY_MODEL,
  createFoodAnalyzer,
  createGeminiFoodAnalyzer,
  normalizeFoodAnalysis,
  parseJsonResponse,
};
