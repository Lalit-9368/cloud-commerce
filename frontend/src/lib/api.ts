export type Product = {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  image: string;
  rating: number;
  badge?: string;
};

export type User = {
  id: string;
  name: string;
  email: string;
};

export type AuthResponse = {
  user: User;
  token: string;
};

export type CheckoutResponse = {
  order: {
    id: string;
    total: number;
    status: string;
    razorpayOrderId?: string;
  };
  payment: {
    keyId: string;
    order: {
      id: string;
      amount: number;
      currency: string;
    };
  };
};

// The browser talks only to the frontend origin. nginx proxies these paths
// to the Docker services, so the same build works locally and through Cloudflare.
export const API = {
  auth: '/api/auth',
  catalog: '/api/catalog',
  checkout: '/api/checkout',
  payment: '/api/payment',
} as const;

async function request<T>(input: RequestInfo | URL, init?: RequestInit): Promise<T> {
  const response = await fetch(input, init);
  const data = (await response.json().catch(() => ({}))) as T & { message?: string };
  if (!response.ok) {
    throw new Error(data.message || `Request failed (${response.status})`);
  }
  return data;
}

export function getToken(): string | null {
  return localStorage.getItem('token');
}

export function getStoredUser(): User | null {
  const raw = localStorage.getItem('user');
  if (!raw) return null;
  try {
    return JSON.parse(raw) as User;
  } catch {
    return null;
  }
}

export async function getProducts(query = '', category = 'All') {
  const params = new URLSearchParams();
  if (query.trim()) params.set('q', query.trim());
  if (category !== 'All') params.set('category', category);
  const suffix = params.toString() ? `?${params.toString()}` : '';
  const data = await request<{ products: Product[] }>(`${API.catalog}/products${suffix}`);
  return data.products;
}

export async function authenticate(
  mode: 'login' | 'register',
  payload: { name?: string; email: string; password: string },
) {
  return request<AuthResponse>(`${API.auth}/${mode}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
}

export async function getCurrentUser() {
  const token = getToken();
  if (!token) return null;
  try {
    const data = await request<{ user: User }>(`${API.auth}/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data.user;
  } catch {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    return null;
  }
}

export async function createOrder(items: Array<{ productId: string; quantity: number }>) {
  const token = getToken();
  if (!token) throw new Error('Please sign in before checkout.');

  return request<CheckoutResponse>(`${API.checkout}/orders`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ items }),
  });
}

export async function verifyPayment(payload: {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
}) {
  return request<{ verified: boolean; status: string }>(`${API.payment}/payments/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
}
