import React, { useState } from 'react';
import { Eye, EyeSlash, CircleNotch, User, Lock, UserCircle } from '@phosphor-icons/react';
import { useAuthStore } from '../store/authStore';
import { useNavigate, Link } from 'react-router-dom';
import { homeRouteForRole } from '../lib/roleRoutes';

const DEMO_ACCOUNTS = [
  { username: 'admin', password: 'admin123', role: 'ADMIN', name: 'System Admin' },
  { username: 'rajan', password: 'inspector123', role: 'INSPECTOR', name: 'Rajan Tiwari' },
  { username: 'priya', password: 'manager123', role: 'QA_MANAGER', name: 'Priya Sharma' },
];

export const LoginPage: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showDemoPanel, setShowDemoPanel] = useState(false);

  const { login, isLoading, error, clearError } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username.trim() || !password.trim()) return;

    try {
      await login(username.trim(), password);
      const role = useAuthStore.getState().user?.role;
      navigate(homeRouteForRole(role), { replace: true });
    } catch {
      // Error is already set in the store
    }
  };

  const fillDemoCredentials = (demo: typeof DEMO_ACCOUNTS[number]) => {
    clearError();
    setUsername(demo.username);
    setPassword(demo.password);
  };

  return (
    <div className="login-container">
      <div className="login-background">
        <div className="blob blob-1"></div>
        <div className="blob blob-2"></div>
      </div>

      <div className="login-card fade-in-up">
        <div className="login-header">
          <div className="login-logo">
            <span>🔍</span>
            <span>LabelLens</span>
          </div>
          <h2>Sign In</h2>
          <p>Packaged Commodity Compliance Dashboard</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="login-error fade-in-up" role="alert">
              <span>{error}</span>
            </div>
          )}

          <div className="login-field">
            <label htmlFor="login-username">Username</label>
            <div className="login-input-wrapper">
              <User size={18} className="login-input-icon" weight="regular" />
              <input
                id="login-username"
                type="text"
                placeholder="Enter your username"
                value={username}
                onChange={(e) => { setUsername(e.target.value); clearError(); }}
                autoComplete="username"
                autoFocus
                disabled={isLoading}
              />
            </div>
          </div>

          <div className="login-field">
            <label htmlFor="login-password">Password</label>
            <div className="login-input-wrapper">
              <Lock size={18} className="login-input-icon" weight="regular" />
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                placeholder="Enter your password"
                value={password}
                onChange={(e) => { setPassword(e.target.value); clearError(); }}
                autoComplete="current-password"
                disabled={isLoading}
              />
              <button
                type="button"
                className="login-password-toggle"
                onClick={() => setShowPassword(!showPassword)}
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                tabIndex={-1}
              >
                {showPassword ? <EyeSlash size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary login-submit"
            disabled={isLoading || !username.trim() || !password.trim()}
          >
            {isLoading ? (
              <>
                <CircleNotch size={18} className="spin" />
                Signing in…
              </>
            ) : (
              'Sign In'
            )}
          </button>
        </form>

        <div className="login-demo-section">
          <button
            type="button"
            className="login-demo-toggle"
            onClick={() => setShowDemoPanel(!showDemoPanel)}
          >
            <UserCircle size={16} />
            {showDemoPanel ? 'Hide' : 'Show'} demo accounts
          </button>

          {showDemoPanel && (
            <div className="login-demo-accounts fade-in-up">
              {DEMO_ACCOUNTS.map((demo) => (
                <button
                  key={demo.username}
                  className="login-demo-chip"
                  onClick={() => fillDemoCredentials(demo)}
                  type="button"
                >
                  <div className="login-demo-chip-avatar">
                    {demo.name.split(' ').map(n => n[0]).join('')}
                  </div>
                  <div className="login-demo-chip-info">
                    <span className="login-demo-chip-name">{demo.name}</span>
                    <span className="login-demo-chip-role">{demo.role}</span>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="register-footer-link">
          Don't have an account? <Link to="/register">Register</Link>
        </div>
      </div>
    </div>
  );
};
