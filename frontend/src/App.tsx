import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import {
  ArrowRight,
  Check,
  ChevronRight,
  Heart,
  Minus,
  Plus,
  Search,
  ShoppingBag,
  Sparkles,
  Star,
  Trash2,
  User,
  X,
} from 'lucide-react';
import {
  authenticate,
  createOrder,
  getProducts,
  getStoredUser,
  getCurrentUser,
  getToken,
  verifyPayment,
  type Product,
  type User as StoreUser,
} from './lib/api';

declare global {
  interface Window {
    Razorpay?: new (options: RazorpayOptions) => RazorpayInstance;
  }
}

type CartItem = Product & { quantity: number };
type AuthMode = 'login' | 'register';

type RazorpayOptions = {
  key: string;
  amount: number;
  currency: string;
  name: string;
  description: string;
  order_id: string;
  prefill?: { name?: string; email?: string };
  theme?: { color: string };
  handler: (response: RazorpayPaymentResponse) => void | Promise<void>;
};

type RazorpayInstance = { open: () => void };
type RazorpayPaymentResponse = {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
};

const categories = ['All', 'Footwear', 'Apparel', 'Tech', 'Accessories', 'Lifestyle'];
const money = (value: number) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value);

async function loadRazorpay(): Promise<void> {
  if (window.Razorpay) return;
  await new Promise<void>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>('script[data-razorpay]');
    if (existing) {
      existing.addEventListener('load', () => resolve(), { once: true });
      existing.addEventListener('error', () => reject(new Error('Unable to load Razorpay.')), { once: true });
      return;
    }
    const script = document.createElement('script');
    script.src = 'https://checkout.razorpay.com/v1/checkout.js';
    script.async = true;
    script.dataset.razorpay = 'true';
    script.onload = () => resolve();
    script.onerror = () => reject(new Error('Unable to load Razorpay.'));
    document.body.appendChild(script);
  });
}

export default function App() {
  const [products, setProducts] = useState<Product[]>([]);
  const [category, setCategory] = useState('All');
  const [query, setQuery] = useState('');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [authMode, setAuthMode] = useState<AuthMode | null>(null);
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState('');
  const [user, setUser] = useState<StoreUser | null>(() => getStoredUser());

  useEffect(() => {
    let active = true;
    getCurrentUser().then((currentUser) => {
      if (active && currentUser) setUser(currentUser);
    });
    setLoading(true);
    getProducts(query, category)
      .then((items) => {
        if (active) setProducts(items);
      })
      .catch((error: Error) => {
        if (active) setNotice(error.message || 'Catalog service is unavailable.');
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [query, category]);

  const total = useMemo(
    () => cart.reduce((sum, item) => sum + item.price * item.quantity, 0),
    [cart],
  );
  const shipping = total === 0 || total >= 4999 ? 0 : 99;
  const itemCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  function addToCart(product: Product) {
    setCart((current) => {
      const existing = current.find((item) => item.id === product.id);
      if (existing) {
        return current.map((item) =>
          item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item,
        );
      }
      return [...current, { ...product, quantity: 1 }];
    });
    setNotice(`${product.name} added to bag.`);
    setDrawerOpen(true);
  }

  function updateCart(id: string, delta: number) {
    setCart((current) =>
      current.flatMap((item) => {
        if (item.id !== id) return [item];
        const quantity = item.quantity + delta;
        return quantity > 0 ? [{ ...item, quantity }] : [];
      }),
    );
  }

  async function checkout() {
    if (cart.length === 0) {
      setNotice('Your bag is empty.');
      return;
    }
    if (!getToken()) {
      setAuthMode('login');
      return;
    }

    try {
      setNotice('Creating your secure order…');
      const data = await createOrder(
        cart.map((item) => ({ productId: item.id, quantity: item.quantity })),
      );
      await loadRazorpay();
      if (!window.Razorpay) throw new Error('Razorpay failed to initialize.');

      const razorpay = new window.Razorpay({
        key: data.payment.keyId,
        amount: data.payment.order.amount,
        currency: data.payment.order.currency,
        name: 'Rove Shop',
        description: 'Secure checkout',
        order_id: data.payment.order.id,
        prefill: { name: user?.name, email: user?.email },
        theme: { color: '#111111' },
        handler: async (response) => {
          try {
            const result = await verifyPayment(response);
            if (!result.verified) throw new Error('Payment verification was rejected.');
            setCart([]);
            setDrawerOpen(false);
            setNotice('Payment verified. Order confirmed.');
          } catch (error) {
            setNotice(error instanceof Error ? error.message : 'Payment verification failed.');
          }
        },
      });
      razorpay.open();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Checkout failed.';
      if (/authentication|invalid or missing token/i.test(message)) {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
        setAuthMode('login');
        setNotice('Your session expired. Please sign in again.');
      } else {
        setNotice(message);
      }
    }
  }

  function handleAuthenticated(nextUser: StoreUser) {
    setUser(nextUser);
    setAuthMode(null);
    setNotice(`Welcome ${nextUser.name}.`);
  }

  function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
    setNotice('You have been signed out.');
  }

  return (
    <div className="app">
      <header className="nav">
        <button className="brand" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
          ROVE<span>STORE</span>
        </button>
        <div className="search">
          <Search size={18} />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search products…"
            aria-label="Search products"
          />
        </div>
        <div className="nav-actions">
          <button
            className="account-button"
            onClick={() => (user ? logout() : setAuthMode('login'))}
            aria-label={user ? 'Sign out' : 'Sign in'}
            title={user ? 'Sign out' : 'Sign in'}
          >
            <User size={20} />
          </button>
          <button className="bag-button" onClick={() => setDrawerOpen(true)} aria-label="Open bag">
            <ShoppingBag size={20} />
            <span>{itemCount}</span>
          </button>
        </div>
      </header>

      <main>
        <section className="hero">
          <div className="hero-copy">
            <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} className="eyebrow">
              <Sparkles size={16} /> NEW SEASON / 2026
            </motion.div>
            <motion.h1 initial={{ opacity: 0, y: 25 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.08 }}>
              Objects designed<br /><i>for everyday.</i>
            </motion.h1>
            <p>Curated essentials across tech, apparel, footwear and lifestyle. Clean design. Honest pricing.</p>
            <button className="primary" onClick={() => document.getElementById('catalog')?.scrollIntoView({ behavior: 'smooth' })}>
              Explore collection <ArrowRight size={18} />
            </button>
          </div>
          <motion.div className="hero-art" initial={{ scale: 0.94, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} transition={{ duration: 0.7 }}>
            {products[2] ? <img src={products[2].image} alt={products[2].name} /> : <div className="hero-placeholder" />}
            <div className="floating-card">
              <span>Featured</span>
              <strong>{products[2]?.name ?? 'Arc Smartwatch'}</strong>
              <small>{money(products[2]?.price ?? 6999)}</small>
            </div>
          </motion.div>
        </section>

        <section id="catalog" className="catalog">
          <div className="section-head">
            <div>
              <div className="eyebrow">THE COLLECTION</div>
              <h2>Shop essentials.</h2>
            </div>
            <div className="filters">
              {categories.map((item) => (
                <button key={item} className={category === item ? 'active' : ''} onClick={() => setCategory(item)}>
                  {item}
                </button>
              ))}
            </div>
          </div>

          {notice && (
            <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} className="notice">
              <span>{notice}</span>
              <button onClick={() => setNotice('')} aria-label="Dismiss notification"><X size={15} /></button>
            </motion.div>
          )}

          {loading ? (
            <div className="loading">Loading catalog…</div>
          ) : products.length === 0 ? (
            <div className="loading">No products found.</div>
          ) : (
            <div className="grid">
              {products.map((product, index) => (
                <ProductCard key={product.id} product={product} index={index} add={addToCart} />
              ))}
            </div>
          )}
        </section>

        <section className="perks">
          <Perk title="Fast delivery" text="Free shipping over ₹4,999" />
          <Perk title="Secure payments" text="Protected by Razorpay" />
          <Perk title="Easy returns" text="7-day return window" />
        </section>
      </main>

      <AnimatePresence>
        {drawerOpen && (
          <CartDrawer
            cart={cart}
            total={total}
            shipping={shipping}
            close={() => setDrawerOpen(false)}
            update={updateCart}
            checkout={checkout}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {authMode && (
          <AuthModal
            mode={authMode}
            close={() => setAuthMode(null)}
            onAuthenticated={handleAuthenticated}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

function ProductCard({ product, index, add }: { product: Product; index: number; add: (product: Product) => void }) {
  return (
    <motion.article className="product" initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true, amount: 0.15 }} transition={{ delay: index * 0.04 }} whileHover={{ y: -7 }}>
      <div className="product-image">
        <img src={product.image} alt={product.name} loading="lazy" />
        {product.badge && <span className="badge">{product.badge}</span>}
        <button className="heart" aria-label={`Favorite ${product.name}`}><Heart size={18} /></button>
        <button className="quick" onClick={() => add(product)}>Add to bag <ArrowRight size={15} /></button>
      </div>
      <div className="product-info">
        <div><span className="category">{product.category}</span><h3>{product.name}</h3></div>
        <strong>{money(product.price)}</strong>
      </div>
      <p>{product.description}</p>
      <div className="rating"><Star size={14} fill="currentColor" /> {product.rating}</div>
    </motion.article>
  );
}

function Perk({ title, text }: { title: string; text: string }) {
  return <div><div className="perk-icon"><Check size={16} /></div><strong>{title}</strong><span>{text}</span></div>;
}

function CartDrawer({ cart, total, shipping, close, update, checkout }: { cart: CartItem[]; total: number; shipping: number; close: () => void; update: (id: string, delta: number) => void; checkout: () => void }) {
  return (
    <motion.div className="overlay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={close}>
      <motion.aside className="drawer" initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} transition={{ type: 'spring', damping: 26 }} onClick={(event) => event.stopPropagation()}>
        <div className="drawer-head">
          <div><span className="eyebrow">YOUR BAG</span><h2>{cart.reduce((sum, item) => sum + item.quantity, 0)} items</h2></div>
          <button className="icon-button" onClick={close} aria-label="Close bag"><X /></button>
        </div>
        {cart.length === 0 ? (
          <div className="empty"><ShoppingBag size={38} /><h3>Your bag is empty.</h3><p>Add something you like from the collection.</p></div>
        ) : (
          <>
            <div className="cart-list">
              {cart.map((item) => (
                <div className="cart-item" key={item.id}>
                  <img src={item.image} alt={item.name} />
                  <div className="cart-main"><strong>{item.name}</strong><span>{money(item.price)}</span><div className="qty"><button onClick={() => update(item.id, -1)}><Minus size={14} /></button><span>{item.quantity}</span><button onClick={() => update(item.id, 1)}><Plus size={14} /></button></div></div>
                  <button className="trash" onClick={() => update(item.id, -item.quantity)} aria-label={`Remove ${item.name}`}><Trash2 size={17} /></button>
                </div>
              ))}
            </div>
            <div className="summary"><div><span>Subtotal</span><strong>{money(total)}</strong></div><div><span>Shipping</span><strong>{shipping ? money(shipping) : 'Free'}</strong></div><div className="grand"><span>Total</span><strong>{money(total + shipping)}</strong></div><button className="primary full" onClick={checkout}>Checkout securely <ChevronRight size={18} /></button></div>
          </>
        )}
      </motion.aside>
    </motion.div>
  );
}

function AuthModal({ mode, close, onAuthenticated }: { mode: AuthMode; close: () => void; onAuthenticated: (user: StoreUser) => void }) {
  const [register, setRegister] = useState(mode === 'register');
  const [form, setForm] = useState({ name: '', email: '', password: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setError('');
    try {
      const result = await authenticate(register ? 'register' : 'login', register ? form : { email: form.email, password: form.password });
      localStorage.setItem('token', result.token);
      localStorage.setItem('user', JSON.stringify(result.user));
      onAuthenticated(result.user);
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : 'Authentication failed.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <motion.div className="overlay" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
      <motion.div className="auth" initial={{ scale: 0.95, y: 10 }} animate={{ scale: 1, y: 0 }}>
        <button className="close" onClick={close} aria-label="Close authentication dialog"><X /></button>
        <span className="eyebrow">ROVE ACCOUNT</span>
        <h2>{register ? 'Create your account.' : 'Welcome back.'}</h2>
        <p>{register ? 'Save your bag and checkout faster.' : 'Sign in to continue to checkout.'}</p>
        {error && <div className="form-error">{error}</div>}
        <form onSubmit={submit}>
          {register && <input placeholder="Full name" required value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} />}
          <input type="email" placeholder="Email address" required value={form.email} onChange={(event) => setForm({ ...form, email: event.target.value })} />
          <input type="password" placeholder="Password (8+ characters)" minLength={8} required value={form.password} onChange={(event) => setForm({ ...form, password: event.target.value })} />
          <button className="primary full" disabled={busy}>{busy ? 'Please wait…' : register ? 'Create account' : 'Sign in'}</button>
        </form>
        <button className="switch" onClick={() => { setRegister(!register); setError(''); }}>{register ? 'Already have an account? Sign in' : 'New here? Create an account'}</button>
      </motion.div>
    </motion.div>
  );
}
