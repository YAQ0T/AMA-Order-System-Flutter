import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { OrderProvider } from './context/OrderContext';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Signup from './pages/Signup';
import MakerDashboard from './pages/MakerDashboard';
import TakerDashboard from './pages/TakerDashboard';
import AdminDashboard from './pages/AdminDashboard';
import PendingApproval from './pages/PendingApproval';
import AccounterDashboard from './pages/AccounterDashboard';

const ProtectedRoute = ({ children, allowedRoles }) => {
  const { user, loading } = useAuth();

  if (loading) return <div className="container">Loading...</div>;
  if (!user) return <Navigate to="/login" />;

  // Support both single role (string) and multiple roles (array)
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
  if (allowedRoles && !roles.includes(user.role)) return <Navigate to="/" />;

  return children;
};

const HomeRedirect = () => {
  const { user, loading } = useAuth();
  if (loading) return <div>Loading...</div>;
  if (!user) return <Navigate to="/login" />;

  // Redirect based on role
  if (user.role === 'admin') return <Navigate to="/admin" />;
  if (user.role === 'maker') return <Navigate to="/maker" />;
  if (user.role === 'taker') return <Navigate to="/taker" />;
  if (user.role === 'accounter') return <Navigate to="/accounter" />;

  return <Navigate to="/login" />;
};

function App() {
  console.log('App component rendering...');

  return (
    <AuthProvider>
      <OrderProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/signup" element={<Signup />} />
            <Route path="/pending-approval" element={<PendingApproval />} />

            <Route path="/" element={<Layout />}>
              <Route index element={<HomeRedirect />} />

              <Route path="admin" element={
                <ProtectedRoute allowedRoles="admin">
                  <AdminDashboard />
                </ProtectedRoute>
              } />

              <Route path="maker" element={
                <ProtectedRoute allowedRoles={['maker', 'admin']}>
                  <MakerDashboard />
                </ProtectedRoute>
              } />

              <Route path="taker" element={
                <ProtectedRoute allowedRoles="taker">
                  <TakerDashboard />
                </ProtectedRoute>
              } />

              <Route path="accounter" element={
                <ProtectedRoute allowedRoles="accounter">
                  <AccounterDashboard />
                </ProtectedRoute>
              } />
            </Route>
          </Routes>
        </BrowserRouter>
      </OrderProvider>
    </AuthProvider>
  );
}

export default App;
