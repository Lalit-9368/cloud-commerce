const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const Razorpay = require('razorpay');
require('dotenv').config();

const app = express();
app.use(cors());

const keyId = process.env.RAZORPAY_KEY_ID || '';
const keySecret = process.env.RAZORPAY_KEY_SECRET || '';
const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || '';
const razorpay = keyId && keySecret ? new Razorpay({ key_id: keyId, key_secret: keySecret }) : null;

app.get('/health', (_, res) => res.json({
  service: 'payment-service',
  status: 'ok',
  configured: Boolean(razorpay),
  webhookConfigured: Boolean(webhookSecret),
}));

app.post('/payments/order', express.json(), async (req, res) => {
  if (!razorpay) return res.status(503).json({ message: 'Razorpay API credentials are not configured' });
  try {
    const { amount, receipt, notes } = req.body || {};
    if (!Number.isInteger(amount) || amount <= 0) return res.status(400).json({ message: 'Amount must be a positive integer in paise' });
    const order = await razorpay.orders.create({ amount, currency: 'INR', receipt: receipt || `rcpt_${Date.now()}`, notes: notes || {} });
    res.status(201).json({ keyId, order });
  } catch (error) {
    console.error('Razorpay order error:', error.message);
    res.status(502).json({ message: 'Unable to create Razorpay order' });
  }
});

app.post('/payments/verify', express.json(), (req, res) => {
  const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body || {};
  if (!keySecret) return res.status(503).json({ message: 'Razorpay API credentials are not configured' });
  if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) return res.status(400).json({ message: 'Missing payment verification fields' });
  const expected = crypto.createHmac('sha256', keySecret).update(`${razorpay_order_id}|${razorpay_payment_id}`).digest('hex');
  const expectedBuffer = Buffer.from(expected, 'hex');
  const receivedBuffer = Buffer.from(String(razorpay_signature), 'hex');
  const valid = expectedBuffer.length === receivedBuffer.length && crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
  res.status(valid ? 200 : 400).json({ verified: valid, status: valid ? 'paid' : 'rejected' });
});

app.post('/payments/webhook', express.raw({ type: 'application/json' }), (req, res) => {
  if (!webhookSecret) return res.status(503).send('Webhook secret not configured');
  const signature = req.headers['x-razorpay-signature'];
  if (!signature || !Buffer.isBuffer(req.body)) return res.status(400).send('Invalid signature');
  const expected = crypto.createHmac('sha256', webhookSecret).update(req.body).digest('hex');
  const expectedBuffer = Buffer.from(expected, 'hex');
  const receivedBuffer = Buffer.from(String(signature), 'hex');
  const valid = expectedBuffer.length === receivedBuffer.length && crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
  if (!valid) return res.status(400).send('Invalid signature');
  try {
    const event = JSON.parse(req.body.toString('utf8'));
    console.log('Razorpay webhook:', event.event);
  } catch {
    return res.status(400).send('Invalid JSON');
  }
  return res.sendStatus(200);
});

const port = Number(process.env.PORT || 4004);
app.listen(port, () => console.log(`Payment service listening on ${port}`));
