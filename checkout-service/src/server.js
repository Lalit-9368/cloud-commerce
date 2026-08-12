const express = require('express');
const cors = require('cors');
const axios = require('axios');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const carts = new Map();
const orders = new Map();

function user(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) throw new Error('missing token');
    req.user = jwt.verify(header.slice(7), JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Authentication required' });
  }
}

async function quote(items) {
  const normalized = [];
  let subtotal = 0;
  for (const item of items || []) {
    const product = (await axios.get(`${process.env.CATALOG_URL || 'http://catalog-service:4002'}/products/${encodeURIComponent(item.productId)}`)).data;
    const quantity = Math.max(1, Math.min(20, Number(item.quantity) || 1));
    const lineTotal = product.price * quantity;
    subtotal += lineTotal;
    normalized.push({ product, quantity, lineTotal });
  }
  const shipping = subtotal === 0 || subtotal >= 4999 ? 0 : 99;
  return { items: normalized, subtotal, shipping, total: subtotal + shipping };
}

app.get('/health', (_, res) => res.json({ service: 'checkout-service', status: 'ok' }));

app.post('/cart/quote', async (req, res) => {
  try {
    res.json(await quote(req.body?.items));
  } catch (error) {
    res.status(400).json({ message: 'Unable to quote cart', detail: error.message });
  }
});

app.post('/orders', user, async (req, res) => {
  try {
    const q = await quote(req.body?.items);
    if (!q.items.length) return res.status(400).json({ message: 'Cart is empty' });
    const id = `ord_${Date.now()}`;
    const order = { id, userId: req.user.sub, items: q.items, total: q.total, status: 'pending', createdAt: new Date().toISOString() };
    orders.set(id, order);
    const payment = await axios.post(`${process.env.PAYMENT_URL || 'http://payment-service:4004'}/payments/order`, {
      amount: q.total * 100,
      receipt: id,
      notes: { orderId: id, userId: req.user.sub },
    });
    order.razorpayOrderId = payment.data.order.id;
    res.status(201).json({ order, payment: payment.data });
  } catch (error) {
    console.error('Checkout error:', error.response?.data || error.message);
    res.status(502).json({ message: 'Unable to create checkout order', detail: error.response?.data || error.message });
  }
});

app.get('/orders/:id', user, (req, res) => {
  const order = orders.get(req.params.id);
  if (!order || order.userId !== req.user.sub) return res.status(404).json({ message: 'Order not found' });
  res.json({ order });
});

const port = Number(process.env.PORT || 4003);
app.listen(port, () => console.log(`Checkout service listening on ${port}`));
