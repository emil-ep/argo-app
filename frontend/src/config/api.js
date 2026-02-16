// Get API URL from runtime environment or build-time environment variable
export const API_BASE_URL = window.ENV?.API_URL || 
  import.meta.env.VITE_API_URL || 
  'http://localhost:3000';

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/api/auth/login',
  REGISTER: '/api/auth/register',
  LOGOUT: '/api/auth/logout',
  ME: '/api/auth/me',
  
  // Products
  PRODUCTS: '/api/products',
  PRODUCT_BY_ID: (id) => `/api/products/${id}`,
  PRODUCTS_BY_CATEGORY: (category) => `/api/products/category/${category}`,
  CATEGORIES: '/api/products/categories',
  
  // Cart
  CART: '/api/cart',
  CART_ITEMS: '/api/cart/items',
  CART_ITEM: (id) => `/api/cart/items/${id}`,
  
  // Orders
  ORDERS: '/api/orders',
  ORDER_BY_ID: (id) => `/api/orders/${id}`,
  ORDER_STATUS: (id) => `/api/orders/${id}/status`,
  ALL_ORDERS: '/api/orders/all'
};

// Made with Bob
