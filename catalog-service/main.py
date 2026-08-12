from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

app = FastAPI(title="Cloud Commerce Catalog Service", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:9000"],
    allow_methods=["GET"],
    allow_headers=["Content-Type", "Authorization"],
)

products = [
 {"id":"p1","name":"AeroRun X1","description":"Lightweight everyday running shoes with responsive foam.","price":10,"category":"Footwear","image":"https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=85","rating":4.7,"badge":"Best Seller"},
 {"id":"p2","name":"Urban Shell Jacket","description":"Water-resistant shell with a clean technical silhouette.","price":9,"category":"Apparel","image":"https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=900&q=85","rating":4.6,"badge":"New"},
 {"id":"p3","name":"Arc Smartwatch","description":"Minimal smartwatch with health tracking and seven-day battery.","price":99,"category":"Tech","image":"https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=85","rating":4.8},
 {"id":"p4","name":"Mono Backpack","description":"Structured 20L commuter backpack with laptop protection.","price":9,"category":"Accessories","image":"https://images.unsplash.com/photo-1553062407-98eeb64c6a62?auto=format&fit=crop&w=900&q=85","rating":4.5},
 {"id":"p5","name":"Studio Headphones","description":"Wireless over-ear headphones with adaptive noise cancellation.","price":59,"category":"Tech","image":"https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=85","rating":4.9,"badge":"Top Rated"},
 {"id":"p6","name":"Everyday Chrono","description":"Stainless-steel chronograph with sapphire-inspired crystal.","price":39,"category":"Accessories","image":"https://images.unsplash.com/photo-1524805444758-089113d48a6d?auto=format&fit=crop&w=900&q=85","rating":4.4},
 {"id":"p7","name":"Cloud Knit","description":"Soft premium knit sweater designed for layering.","price":19,"category":"Apparel","image":"https://images.unsplash.com/photo-1434389677669-e08b4cac3105?auto=format&fit=crop&w=900&q=85","rating":4.6},
 {"id":"p8","name":"Trail Bottle","description":"Double-wall insulated bottle for work, gym and travel.","price":92,"category":"Lifestyle","image":"https://images.unsplash.com/photo-1602143407151-7111542de6e8?auto=format&fit=crop&w=900&q=85","rating":4.7},
]

@app.get('/health')
def health(): return {"service":"catalog-service","status":"ok"}
@app.get('/products')
def list_products(category: Optional[str] = None, q: Optional[str] = None):
    data = products
    if category and category != 'All': data = [p for p in data if p['category'] == category]
    if q: data = [p for p in data if q.lower() in (p['name'] + ' ' + p['description']).lower()]
    return {"products": data, "count": len(data)}
@app.get('/products/{product_id}')
def get_product(product_id: str):
    for p in products:
        if p['id'] == product_id: return p
    raise HTTPException(404, 'Product not found')
