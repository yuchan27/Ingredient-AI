import 'dotenv/config';

import { neon } from '@neondatabase/serverless';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import jwt from 'jsonwebtoken';

const app = express();
const port = Number(process.env.PORT || 8787);
const jwtSecret = process.env.JWT_SECRET;
const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL is required');
}

if (!jwtSecret) {
  throw new Error('JWT_SECRET is required');
}

const sql = neon(databaseUrl);

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'ingredient-ai-neon-api' });
});

app.post('/auth/signup', async (req, res, next) => {
  try {
    const { email, password } = readCredentials(req.body);
    const passwordHash = await bcrypt.hash(password, 12);
    const [user] = await sql`
      INSERT INTO app_users (email, password_hash)
      VALUES (${email}, ${passwordHash})
      RETURNING id, email
    `;
    res.status(201).json(authResponse(user));
  } catch (error) {
    next(error);
  }
});

app.post('/auth/login', async (req, res, next) => {
  try {
    const { email, password } = readCredentials(req.body);
    const [user] = await sql`
      SELECT id, email, password_hash
      FROM app_users
      WHERE email = ${email}
    `;
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ message: 'Email or password is incorrect' });
    }
    res.json(authResponse(user));
  } catch (error) {
    next(error);
  }
});

app.post('/sync/history', requireUser, async (req, res, next) => {
  try {
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    const synced = [];

    for (const item of items) {
      const localId = String(item.localId || `history_${item.localDbId || Date.now()}`);
      const result = item.result && typeof item.result === 'object' ? item.result : {};
      const [row] = await sql`
        INSERT INTO analysis_history (user_id, local_id, analyzed_at, image_path, result, updated_at)
        VALUES (
          ${req.user.id},
          ${localId},
          ${nullableDate(item.date)},
          ${item.imagePath || null},
          ${JSON.stringify(result)}::jsonb,
          now()
        )
        ON CONFLICT (user_id, local_id)
        DO UPDATE SET
          analyzed_at = EXCLUDED.analyzed_at,
          image_path = EXCLUDED.image_path,
          result = EXCLUDED.result,
          updated_at = now()
        RETURNING id
      `;
      synced.push({
        localDbId: item.localDbId,
        localId,
        cloudId: row.id,
      });
    }

    res.json({ synced });
  } catch (error) {
    next(error);
  }
});

app.post('/sync/food-entries', requireUser, async (req, res, next) => {
  try {
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    const synced = [];

    for (const item of items) {
      const localId = String(item.localId || item.local_id || Date.now());
      const [row] = await sql`
        INSERT INTO food_entries (
          user_id, local_id, food_name, consumed_at, meal_type, serving_size,
          serving_unit, calories, protein, carbs, fat, sugar, sodium, fiber,
          health_score, notes, source, updated_at, deleted_at
        )
        VALUES (
          ${req.user.id},
          ${localId},
          ${String(item.foodName || item.food_name || '未命名食物')},
          ${nullableDate(item.consumedAt || item.consumed_at) || new Date().toISOString()},
          ${String(item.mealType || item.meal_type || 'meal')},
          ${numberValue(item.servingSize || item.serving_size, 1)},
          ${String(item.servingUnit || item.serving_unit || 'serving')},
          ${numberValue(item.calories, 0)},
          ${numberValue(item.protein, 0)},
          ${numberValue(item.carbs, 0)},
          ${numberValue(item.fat, 0)},
          ${numberValue(item.sugar, 0)},
          ${numberValue(item.sodium, 0)},
          ${numberValue(item.fiber, 0)},
          ${numberValue(item.healthScore || item.health_score, 0)},
          ${String(item.notes || '')},
          ${String(item.source || 'manual')},
          now(),
          ${nullableDate(item.deletedAt || item.deleted_at)}
        )
        ON CONFLICT (user_id, local_id)
        DO UPDATE SET
          food_name = EXCLUDED.food_name,
          consumed_at = EXCLUDED.consumed_at,
          meal_type = EXCLUDED.meal_type,
          serving_size = EXCLUDED.serving_size,
          serving_unit = EXCLUDED.serving_unit,
          calories = EXCLUDED.calories,
          protein = EXCLUDED.protein,
          carbs = EXCLUDED.carbs,
          fat = EXCLUDED.fat,
          sugar = EXCLUDED.sugar,
          sodium = EXCLUDED.sodium,
          fiber = EXCLUDED.fiber,
          health_score = EXCLUDED.health_score,
          notes = EXCLUDED.notes,
          source = EXCLUDED.source,
          updated_at = now(),
          deleted_at = EXCLUDED.deleted_at
        RETURNING id
      `;
      synced.push({ localId, cloudId: row.id });
    }

    res.json({ synced });
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  if (error.code === '23505') {
    return res.status(409).json({ message: 'Account already exists' });
  }
  if (error.status) {
    return res.status(error.status).json({ message: error.message });
  }
  console.error(error);
  res.status(500).json({ message: 'Server error' });
});

app.listen(port, () => {
  console.log(`Ingredient AI Neon API listening on http://localhost:${port}`);
});

function readCredentials(body) {
  const email = String(body.email || '').trim().toLowerCase();
  const password = String(body.password || '');
  if (!email.includes('@')) {
    throw httpError(400, 'Valid email is required');
  }
  if (password.length < 6) {
    throw httpError(400, 'Password must be at least 6 characters');
  }
  return { email, password };
}

function authResponse(user) {
  return {
    user: {
      id: user.id,
      email: user.email,
    },
    token: jwt.sign({ sub: user.id, email: user.email }, jwtSecret, {
      expiresIn: '30d',
    }),
  };
}

function requireUser(req, res, next) {
  const header = req.get('Authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
  try {
    const payload = jwt.verify(token, jwtSecret);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch (_error) {
    res.status(401).json({ message: 'Unauthorized' });
  }
}

function nullableDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function numberValue(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function httpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}
