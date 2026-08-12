export type Product = { id: string; name: string; description: string; price: number; category: string; image: string; rating: number; badge?: string };
export type CartItem = { productId: string; quantity: number };
