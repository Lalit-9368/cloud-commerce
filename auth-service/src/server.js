const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const USERS_FILE = process.env.USERS_FILE || path.join(__dirname, '..', 'data', 'users.json');

function loadUsers() {
  try {
    const raw = fs.readFileSync(USERS_FILE, 'utf8');
    const data = JSON.parse(raw);
    return new Map(Object.entries(data));
  } catch {
    return new Map();
  }
}

const users = loadUsers();

function saveUsers() {
  fs.mkdirSync(path.dirname(USERS_FILE), { recursive: true });
  const data = Object.fromEntries(users.entries());
  fs.writeFileSync(USERS_FILE, JSON.stringify(data, null, 2));
}

function sign(user) {
  return jwt.sign(
    { sub: user.id, email: user.email, name: user.name },
    JWT_SECRET,
    { expiresIn: '2h' },
  );
}

function auth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) throw new Error('missing token');
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Invalid or missing token' });
  }
}

app.get('/health', (_, res) => res.json({ service: 'auth-service', status: 'ok' }));

app.post('/auth/register', async (req, res) => {
  const name = String(req.body?.name || '').trim();
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  if (!name || !email || !password || password.length < 8) {
    return res.status(400).json({ message: 'Name, email and password (8+ chars) are required' });
  }
  if (users.has(email)) return res.status(409).json({ message: 'Account already exists' });
  const user = {
    id: `usr_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    name,
    email,
    passwordHash: await bcrypt.hash(password, 12),
  };
  users.set(email, user);
  saveUsers();
  return res.status(201).json({
    user: { id: user.id, name: user.name, email: user.email },
    token: sign(user),
  });
});

app.post('/auth/login', async (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase();
  const password = String(req.body?.password || '');
  const user = users.get(email);
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ message: 'Invalid email or password' });
  }
  return res.json({
    user: { id: user.id, name: user.name, email: user.email },
    token: sign(user),
  });
});

app.get('/auth/me', auth, (req, res) =>
  res.json({ user: { id: req.user.sub, name: req.user.name, email: req.user.email } }),
);

const port = Number(process.env.PORT || 4001);
app.listen(port, () => console.log(`Auth service listening on ${port}`));
