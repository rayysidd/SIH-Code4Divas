import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, SignOut, Moon, Sun, Gear as GearIcon, Info, Gavel, CaretRight } from '@phosphor-icons/react';
import { useAuthStore } from '../store/authStore';

export const SettingsPage: React.FC = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [isDark, setIsDark] = useState(() => localStorage.getItem('ll_theme') === 'dark');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    localStorage.setItem('ll_theme', isDark ? 'dark' : 'light');
  }, [isDark]);

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  return (
    <>
      <h2 style={{ marginBottom: 'var(--space-6)' }}>Settings</h2>

      {/* Account Section */}
      <div className="settings-section">
        <div className="settings-section-title">Account</div>
        <div style={{ borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--elev-1)' }}>
          <div className="settings-item">
            <User size={20} className="settings-item-icon" />
            <div style={{ flex: 1 }}>
              <div className="settings-item-label" style={{ fontWeight: 600 }}>{user?.full_name || 'User'}</div>
              <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>
                @{user?.username || 'unknown'} · {user?.role || 'N/A'}
              </div>
            </div>
          </div>
          <div className="settings-item destructive" onClick={handleLogout}>
            <SignOut size={20} className="settings-item-icon" />
            <span className="settings-item-label">Log Out</span>
            <CaretRight size={16} style={{ color: 'var(--color-text-tertiary)' }} />
          </div>
        </div>
      </div>

      {/* Appearance Section */}
      <div className="settings-section">
        <div className="settings-section-title">Appearance</div>
        <div style={{ borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--elev-1)' }}>
          <div className="settings-item" onClick={() => setIsDark(!isDark)}>
            {isDark ? <Moon size={20} className="settings-item-icon" /> : <Sun size={20} className="settings-item-icon" />}
            <span className="settings-item-label">Dark Mode</span>
            <span className="settings-item-value">{isDark ? 'On' : 'Off'}</span>
          </div>
        </div>
      </div>

      {/* About Section */}
      <div className="settings-section">
        <div className="settings-section-title">About</div>
        <div style={{ borderRadius: 'var(--radius-lg)', overflow: 'hidden', boxShadow: 'var(--elev-1)' }}>
          <div className="settings-item">
            <Info size={20} className="settings-item-icon" />
            <span className="settings-item-label">App Version</span>
            <span className="settings-item-value">1.0.0 (SIH 2026)</span>
          </div>
          <div className="settings-item">
            <Gavel size={20} className="settings-item-icon" />
            <span className="settings-item-label">Rules Engine Version</span>
            <span className="settings-item-value">LMPC 2024.01</span>
          </div>
          <div className="settings-item">
            <GearIcon size={20} className="settings-item-icon" />
            <span className="settings-item-label">Backend API</span>
            <span className="settings-item-value mono" style={{ fontSize: '0.75rem' }}>
              {import.meta.env.VITE_API_BASE_URL || 'localhost:8000'}
            </span>
          </div>
        </div>
      </div>
    </>
  );
};
