require('dotenv').config();

const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const port = Number(process.env.PORT || 3000);

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

const supabaseUrl = required('SUPABASE_URL');
const supabaseServiceRoleKey = required('SUPABASE_SERVICE_ROLE_KEY');
const firebaseServiceAccountJson = required('FIREBASE_SERVICE_ACCOUNT_JSON');

let serviceAccount;
try {
  serviceAccount = JSON.parse(firebaseServiceAccountJson);
} catch (error) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON must contain valid one-line JSON');
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const configuredOrigins = (process.env.CORS_ORIGIN || '*')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

// Firebase Auth uses popup and Google endpoints from the Flutter browser app.
// Keep Helmet's safe headers but leave CSP to the Flutter/Firebase deployment
// configuration so the existing login flow is not blocked by a default policy.
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({
  origin(origin, callback) {
    if (!origin || configuredOrigins.includes('*') || configuredOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Origin is not allowed by CORS'));
  },
}));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// In the Railway Docker image, Flutter's compiled web files are copied to
// /app/build/web. The relative path also works when this server is run from
// the repository root during local development.
const flutterWebRoot = path.resolve(__dirname, '../../build/web');
const flutterIndex = path.join(flutterWebRoot, 'index.html');
if (fs.existsSync(flutterWebRoot)) {
  app.use(express.static(flutterWebRoot, { index: false }));
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'myrsu-api', timestamp: new Date().toISOString() });
});

function cleanProfile(user) {
  return {
    id: user.uid,
    name: user.name || user.displayName || '',
    email: user.email || '',
    photo_url: user.photoUrl || user.photoURL || null,
  };
}

async function requireUser(req, res, next) {
  const header = req.get('authorization') || '';
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Firebase bearer token' });
  }
  try {
    req.firebaseUser = await admin.auth().verifyIdToken(header.slice(7));
    return next();
  } catch (_error) {
    return res.status(401).json({ error: 'Invalid or expired Firebase token' });
  }
}

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

function validateTimeEntry(body) {
  const day = Number(body.day);
  const startMinutes = Number(body.startMinutes ?? body.start_minutes);
  const endMinutes = Number(body.endMinutes ?? body.end_minutes);
  if (!Number.isInteger(day) || day < 0 || day > 6) return 'day must be an integer from 0 to 6';
  if (!Number.isInteger(startMinutes) || startMinutes < 0 || startMinutes > 1439) return 'startMinutes is invalid';
  if (!Number.isInteger(endMinutes) || endMinutes < 1 || endMinutes > 1440 || endMinutes <= startMinutes) return 'endMinutes is invalid';
  return null;
}

function timetablePayload(body) {
  return {
    code: String(body.code || ''),
    title: String(body.title || ''),
    section: String(body.section || ''),
    room: String(body.room || ''),
    instructor: String(body.instructor || ''),
    day: Number(body.day),
    start_minutes: Number(body.startMinutes ?? body.start_minutes),
    end_minutes: Number(body.endMinutes ?? body.end_minutes),
    color_index: Number(body.colorIndex ?? body.color_index ?? 0),
  };
}

function eventPayload(body) {
  return {
    title: String(body.title || ''),
    notes: String(body.notes || ''),
    event_date: body.eventDate || body.event_date,
    all_day: body.allDay ?? body.all_day ?? true,
    start_minutes: body.startMinutes ?? body.start_minutes ?? null,
    end_minutes: body.endMinutes ?? body.end_minutes ?? null,
    location: String(body.location || ''),
    color_index: Number(body.colorIndex ?? body.color_index ?? 0),
    remind_day_before: body.remindDayBefore ?? body.remind_day_before ?? true,
  };
}

app.get('/api/me', requireUser, asyncRoute(async (req, res) => {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', req.firebaseUser.uid).maybeSingle();
  if (error) throw error;
  if (data) return res.json(data);
  const { data: created, error: createError } = await supabase.from('profiles').insert(cleanProfile(req.firebaseUser)).select().single();
  if (createError) throw createError;
  return res.status(201).json(created);
}));

app.put('/api/me', requireUser, asyncRoute(async (req, res) => {
  const allowed = ['name', 'student_id', 'major_id', 'major_name', 'photo_url'];
  const updates = Object.fromEntries(Object.entries(req.body || {}).filter(([key]) => allowed.includes(key)));
  if (updates.name !== undefined) updates.name = String(updates.name);
  updates.email = req.firebaseUser.email || '';
  const { data, error } = await supabase.from('profiles').upsert({ id: req.firebaseUser.uid, ...updates }, { onConflict: 'id' }).select().single();
  if (error) throw error;
  return res.json(data);
}));

app.get('/api/majors', asyncRoute(async (_req, res) => {
  const { data, error } = await supabase.from('majors').select('*').order('name');
  if (error) throw error;
  return res.json(data);
}));

app.get('/api/timetable', requireUser, asyncRoute(async (req, res) => {
  const { data, error } = await supabase.from('timetable_entries').select('*').eq('user_id', req.firebaseUser.uid).order('day').order('start_minutes');
  if (error) throw error;
  return res.json(data);
}));

app.post('/api/timetable', requireUser, asyncRoute(async (req, res) => {
  const validationError = validateTimeEntry(req.body || {});
  if (validationError) return res.status(400).json({ error: validationError });
  const { data, error } = await supabase.from('timetable_entries').insert({ user_id: req.firebaseUser.uid, ...timetablePayload(req.body) }).select().single();
  if (error) throw error;
  return res.status(201).json(data);
}));

app.put('/api/timetable/:id', requireUser, asyncRoute(async (req, res) => {
  const validationError = validateTimeEntry(req.body || {});
  if (validationError) return res.status(400).json({ error: validationError });
  const { data, error } = await supabase.from('timetable_entries').update(timetablePayload(req.body)).eq('id', req.params.id).eq('user_id', req.firebaseUser.uid).select().single();
  if (error) throw error;
  return res.json(data);
}));

app.delete('/api/timetable/:id', requireUser, asyncRoute(async (req, res) => {
  const { error } = await supabase.from('timetable_entries').delete().eq('id', req.params.id).eq('user_id', req.firebaseUser.uid);
  if (error) throw error;
  return res.status(204).send();
}));

app.get('/api/events', requireUser, asyncRoute(async (req, res) => {
  const { data, error } = await supabase.from('personal_events').select('*').eq('user_id', req.firebaseUser.uid).order('event_date');
  if (error) throw error;
  return res.json(data);
}));

app.post('/api/events', requireUser, asyncRoute(async (req, res) => {
  const payload = eventPayload(req.body || {});
  if (!payload.title || !payload.event_date) return res.status(400).json({ error: 'title and eventDate are required' });
  const { data, error } = await supabase.from('personal_events').insert({ user_id: req.firebaseUser.uid, ...payload }).select().single();
  if (error) throw error;
  return res.status(201).json(data);
}));

app.put('/api/events/:id', requireUser, asyncRoute(async (req, res) => {
  const payload = eventPayload(req.body || {});
  if (!payload.title || !payload.event_date) return res.status(400).json({ error: 'title and eventDate are required' });
  const { data, error } = await supabase.from('personal_events').update(payload).eq('id', req.params.id).eq('user_id', req.firebaseUser.uid).select().single();
  if (error) throw error;
  return res.json(data);
}));

app.delete('/api/events/:id', requireUser, asyncRoute(async (req, res) => {
  const { error } = await supabase.from('personal_events').delete().eq('id', req.params.id).eq('user_id', req.firebaseUser.uid);
  if (error) throw error;
  return res.status(204).send();
}));

// Flutter Web is a single-page application. Send its index file for browser
// routes that are not API routes, while leaving unknown API paths as 404s.
app.get(/^(?!\/api(?:\/|$)).*/, (_req, res) => {
  if (!fs.existsSync(flutterIndex)) {
    return res.status(503).json({ error: 'Flutter web build is not available' });
  }
  return res.sendFile(flutterIndex);
});

app.use((error, _req, res, _next) => {
  console.error(error);
  if (res.headersSent) return;
  return res.status(500).json({ error: 'Internal server error' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`MyRSU API listening on port ${port}`);
});
