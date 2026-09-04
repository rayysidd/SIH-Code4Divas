/**
 * ProtectedRoute — Wraps dashboard routes to enforce authentication.
 * Shows a loading state while rehydrating the session, redirects to /login
 * if not authenticated.
 */

import React, { useEffect } from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

export const ProtectedRoute: React.FC = () => {
  const { user, isLoading, rehydrate, accessToken } = useAuthStore();

  useEffect(() => {
    if (!user && !isLoading) {
      rehydrate();
    }
  }, [user, isLoading, rehydrate]);

  if (isLoading) {
    return (
      <div className="auth-loading-screen">
        <div className="auth-loading-content">
          <div className="auth-loading-logo">
            <span>🔍</span>
            <span>LabelLens</span>
          </div>
          <div className="auth-loading-spinner" />
          <p>Verifying session…</p>
        </div>
      </div>
    );
  }

  if (!user || !accessToken) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};
