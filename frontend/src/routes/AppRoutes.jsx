import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { AuthProvider, useAuth } from '../context/AuthContext';
import ProtectedRoute from './ProtectedRoute';
import PublicRoute from './PublicRoute';
import Layout from '../components/layout/Layout';
import AdminLayout from '../components/admin/AdminLayout';

const LandingPage = lazy(() => import('../pages/LandingPage'));
const PrivacyPolicy = lazy(() => import('../pages/PrivacyPolicy'));
const LoginPage = lazy(() => import('../pages/Login'));
const NotFound = lazy(() => import('../pages/NotFound'));
const Dashboard = lazy(() => import('../pages/admin/Dashboard'));
const Users = lazy(() => import('../pages/admin/Users'));
const UserProfile = lazy(() => import('../pages/admin/UserProfile'));
const Workers = lazy(() => import('../pages/admin/Workers'));
const WorkerProfile = lazy(() => import('../pages/admin/WorkerProfile'));
const Categories = lazy(() => import('../pages/admin/Categories'));
const Orders = lazy(() => import('../pages/admin/Orders'));
const Ratings = lazy(() => import('../pages/admin/Ratings'));
const Settings = lazy(() => import('../pages/admin/Settings'));

const PageLoader = () => (
  <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '50vh' }}>
    <div className="spinner-border text-primary" role="status">
      <span className="visually-hidden">Loading...</span>
    </div>
  </div>
);

function UnauthorizedPage() {
  const { logout } = useAuth();
  const navigate = useNavigate();
  const handleLogout = () => { logout(); navigate('/login', { replace: true }); };
  return (
    <div className="container-fluid vh-100 d-flex justify-content-center align-items-center" style={{ backgroundColor: '#f1f5f9' }}>
      <div className="text-center">
        <h1 className="display-3 fw-bold" style={{ color: '#ef4444' }}>403</h1>
        <h4 className="fw-bold mb-2" style={{ color: '#1e293b' }}>Unauthorized Access</h4>
        <p className="text-muted mb-4">You do not have permission to access this page.</p>
        <div className="d-flex gap-3 justify-content-center">
          <a href="/" className="btn text-white px-4 py-2" style={{ background: '#6366f1', border: 'none', borderRadius: '10px' }}>
            <i className="bi bi-house-door me-2"></i>
            Back to Home
          </a>
          <button onClick={handleLogout} className="btn px-4 py-2" style={{ background: '#ef4444', color: 'white', border: 'none', borderRadius: '10px' }}>
            <i className="bi bi-box-arrow-right me-2"></i>
            Logout
          </button>
        </div>
      </div>
    </div>
  );
}

function AppRoutes() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Suspense fallback={<PageLoader />}>
          <Routes>
            <Route element={<Layout />}>
              <Route path="/" element={<LandingPage />} />
              <Route path="/privacy" element={<PrivacyPolicy />} />
            </Route>

            <Route
              path="/login"
              element={
                <PublicRoute>
                  <LoginPage />
                </PublicRoute>
              }
            />

            <Route
              path="/admin"
              element={
                <ProtectedRoute requiredRole="admin">
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="users/:id" element={<UserProfile />} />
              <Route path="workers" element={<Workers />} />
              <Route path="workers/:id" element={<WorkerProfile />} />
              <Route path="categories" element={<Categories />} />
              <Route path="orders" element={<Orders />} />
              <Route path="ratings" element={<Ratings />} />
              <Route path="settings" element={<Settings />} />
            </Route>

            <Route path="/unauthorized" element={<UnauthorizedPage />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default AppRoutes;
