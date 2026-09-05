import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuthStore } from './store/authStore';
import { Sidebar } from './components/Sidebar';
import { TopBar } from './components/TopBar';
import { ProtectedRoute } from './components/ProtectedRoute';
import { LoginPage } from './pages/LoginPage';
import { RegisterPage } from './pages/RegisterPage';
import { OverviewPage } from './pages/OverviewPage';
import { ProductsPage } from './pages/ProductsPage';
import { ViolationsPage } from './pages/ViolationsPage';
import { EcommercePage } from './pages/EcommercePage';
import { AnalyticsPage } from './pages/AnalyticsPage';
import { ScanUploadPage } from './pages/ScanUploadPage';
import { ScanDetailPage } from './pages/ScanDetailPage';
import { ScanHistoryPage } from './pages/ScanHistoryPage';
import { CitizenReportsPage } from './pages/CitizenReportsPage';
import { BatchPage } from './pages/BatchPage';
import { SettingsPage } from './pages/SettingsPage';
import { InviteCodesPage } from './pages/admin/InviteCodesPage';
import { UserManagementPage } from './pages/admin/UserManagementPage';
import { AuditLogPage } from './pages/admin/AuditLogPage';
import { RulesVersionPage } from './pages/admin/RulesVersionPage';
import { DistrictAnalyticsPage } from './pages/admin/DistrictAnalyticsPage';
import { EcomOverviewPage } from './pages/EcomOverviewPage';
import { CitizenNoticePage } from './pages/CitizenNoticePage';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,   // 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

/* ── Dashboard Layout Shell ────────────────────────────────────────────── */

const DashboardLayout: React.FC = () => {
  return (
    <div className="app-layout">
      <Sidebar />
      <div className="main-content">
        <TopBar />
        <main className="page-content" id="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

/* ── App Root ──────────────────────────────────────────────────────────── */

const App: React.FC = () => {
  const rehydrate = useAuthStore((s) => s.rehydrate);

  useEffect(() => {
    rehydrate();
  }, [rehydrate]);

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <a href="#main-content" className="skip-to-content">
          Skip to content
        </a>
        <Routes>
          {/* Public */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Protected Dashboard */}
          <Route element={<ProtectedRoute />}>
            <Route element={<DashboardLayout />}>
              <Route path="/dashboard" element={<OverviewPage />} />
              <Route path="/dashboard/ecom/overview" element={<EcomOverviewPage />} />
              <Route path="/dashboard/citizen-notice" element={<CitizenNoticePage />} />
              <Route path="/dashboard/products" element={<ProductsPage />} />
              <Route path="/dashboard/violations" element={<ViolationsPage />} />
              <Route path="/dashboard/ecommerce" element={<EcommercePage />} />
              <Route path="/dashboard/analytics" element={<AnalyticsPage />} />
              <Route path="/dashboard/scan/new" element={<ScanUploadPage />} />
              <Route path="/dashboard/scan/:scanId" element={<ScanDetailPage />} />
              <Route path="/dashboard/history" element={<ScanHistoryPage />} />
              <Route path="/dashboard/citizen-reports" element={<CitizenReportsPage />} />
              <Route path="/dashboard/batch" element={<BatchPage />} />
              <Route path="/dashboard/admin/invite-codes" element={<InviteCodesPage />} />
              <Route path="/dashboard/admin/users" element={<UserManagementPage />} />
              <Route path="/dashboard/admin/audit-log" element={<AuditLogPage />} />
              <Route path="/dashboard/admin/rules-version" element={<RulesVersionPage />} />
              <Route path="/dashboard/admin/analytics" element={<DistrictAnalyticsPage />} />
              <Route path="/dashboard/settings" element={<SettingsPage />} />
            </Route>
          </Route>

          {/* Catch-all redirect */}
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
};

export default App;
