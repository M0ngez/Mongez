import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

let isRefreshing = false;
let failedQueue = [];

const processQueue = (error, token = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

// No global Content-Type. Axios infers the right header from the body:
// `application/json` for plain objects, `multipart/form-data; boundary=…`
// for FormData. Setting a default here poisons multipart uploads — the
// boundary is never appended, the backend can't parse the body, and
// `request.FILES` comes back empty. This was the reason dashboard
// avatar uploads silently failed.
const api = axios.create({
  baseURL: API_BASE,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If the backend says "not admin" (403) on an admin-only endpoint,
    // the stored token likely belongs to a non-admin user.
    // Clear stale auth state and force re-login.
    if (error.response?.status === 403 && originalRequest.url?.includes('/admin/')) {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('user');
      window.location.href = '/login';
      return Promise.reject(error);
    }

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return api(originalRequest);
        }).catch((err) => Promise.reject(err));
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) throw new Error('No refresh token');

        const { data } = await axios.post(`${API_BASE}/auth/token/refresh/`, {
          refresh: refreshToken,
        });

        localStorage.setItem('accessToken', data.access);
        if (data.refresh) {
          localStorage.setItem('refreshToken', data.refresh);
        }
        processQueue(null, data.access);
        originalRequest.headers.Authorization = `Bearer ${data.access}`;
        return api(originalRequest);
      } catch (err) {
        processQueue(err, null);
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
        window.location.href = '/login';
        return Promise.reject(error);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);

export const authAPI = {
  login: (username, password) =>
    api.post('/auth/login/', { username, password }),
  register: (data) => api.post('/auth/register/', data),
  refreshToken: (refresh) =>
    api.post('/auth/token/refresh/', { refresh }),
  getProfile: () => api.get('/users/me/'),
  updateProfile: (data) => api.patch('/users/me/', data),
};

export const categoriesAPI = {
  list: () => api.get('/categories/'),
  create: (data) => api.post('/categories/create/', data),
};

// Public payload powering the landing page — site config + live DB stats.
export const siteAPI = {
  home: () => api.get('/home/'),
};

// Static reference list shared with the mobile. Cached in-memory by
// listGovernorates() below so the dropdown doesn't re-fetch on every
// modal open.
let _govCache = null;
export const referenceAPI = {
  listGovernorates: async () => {
    if (_govCache) return _govCache;
    const res = await api.get('/governorates/');
    _govCache = res.data;
    return _govCache;
  },
};

export const workersAPI = {
  list: (params) => api.get('/workers/', { params }),
  detail: (id) => api.get(`/workers/${id}/`),
  create: (data) => api.post('/workers/create/', data),
  myProfile: () => api.get('/workers/me/'),
  updateMyProfile: (data) => api.patch('/workers/me/', data),
  myRatings: () => api.get('/ratings/worker/me/'),
  ratings: (id) => api.get(`/ratings/worker/${id}/`),
};

export const ordersAPI = {
  list: (params) => api.get('/orders/', { params }),
  create: (data) => api.post('/orders/', data),
  detail: (id) => api.get(`/orders/${id}/`),
  accept: (id) => api.post(`/orders/${id}/accept/`),
  reject: (id) => api.post(`/orders/${id}/reject/`),
  cancel: (id) => api.post(`/orders/${id}/cancel/`),
  markFinished: (id) => api.post(`/orders/${id}/complete/`),
  confirmCompletion: (id) => api.post(`/orders/${id}/confirm-completion/`),
};

export const ratingsAPI = {
  create: (data) => api.post('/ratings/', data),
};

export const favoritesAPI = {
  list: () => api.get('/favorites/'),
  add: (workerId) => api.post('/favorites/', { worker_id: workerId }),
  remove: (id) => api.delete(`/favorites/${id}/`),
};

export const notificationsAPI = {
  list: () => api.get('/notifications/'),
  markRead: (id) => api.post(`/notifications/${id}/read/`),
  markAllRead: () => api.post('/notifications/read-all/'),
};

// Account deletion. The public site has no client login, so the mobile app
// mints a short-lived signed token first and puts it in this page's URL;
// the confirm call is anonymous and authorised by that token alone.
export const accountAPI = {
  requestDeletionToken: () => api.post('/auth/deletion-token/'),
  confirmDeletion: (token) => api.post('/auth/delete-account/', { token }),
};

export const adminAPI = {
  dashboard: () => api.get('/admin/dashboard/'),
  users: {
    list: (params) => api.get('/admin/users/', { params }),
    create: (data) => api.post('/admin/users/create/', data),
    detail: (id) => api.get(`/admin/users/${id}/`),
    profile: (id) => api.get(`/admin/users/${id}/profile/`),
    update: (id, data) => api.patch(`/admin/users/${id}/`, data),
    delete: (id) => api.delete(`/admin/users/${id}/`),
  },
  categories: {
    update: (id, data) => api.patch(`/admin/categories/${id}/`, data),
    delete: (id) => api.delete(`/admin/categories/${id}/`),
  },
  payments: {
    list: () => api.get('/admin/payments/'),
  },
  orders: {
    list: (params) => api.get('/admin/orders/', { params }),
    updateStatus: (id, status) => api.patch(`/admin/orders/${id}/status/`, { status }),
  },
  ratings: {
    list: () => api.get('/admin/ratings/'),
  },
  siteConfig: {
    get: () => api.get('/admin/site-config/'),
    update: (data) => api.put('/admin/site-config/', data),
  },
  workers: {
    list: (params) => api.get('/admin/workers/', { params }),
    detail: (id) => api.get(`/admin/workers/${id}/`),
    profile: (id) => api.get(`/admin/workers/${id}/profile/`),
    update: (id, data) => api.patch(`/admin/workers/${id}/`, data),
    verify: (id) => api.post(`/admin/workers/${id}/verify/`),
    reject: (id, reason) => api.post(`/admin/workers/${id}/reject/`, { reason }),
  },
  exports: {
    orders: () => api.get('/admin/export/orders.csv', { responseType: 'blob' }),
    workers: () => api.get('/admin/export/workers.csv', { responseType: 'blob' }),
    users: () => api.get('/admin/export/users.csv', { responseType: 'blob' }),
    payments: () => api.get('/admin/export/payments.csv', { responseType: 'blob' }),
    categories: () => api.get('/admin/export/categories.csv', { responseType: 'blob' }),
    ratings: () => api.get('/admin/export/ratings.csv', { responseType: 'blob' }),
  },
};

export default api;
