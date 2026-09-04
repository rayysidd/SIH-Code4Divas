import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, SignOut, Sun, Moon, MagnifyingGlass } from '@phosphor-icons/react';
import { useAuthStore } from '../store/authStore';

export const TopBar: React.FC = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [isDark, setIsDark] = useState(() => {
    return localStorage.getItem('ll_theme') === 'dark';
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
    localStorage.setItem('ll_theme', isDark ? 'dark' : 'light');
  }, [isDark]);

  const handleLogout = () => {
    logout();
    navigate('/login', { replace: true });
  };

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = searchQuery.trim();
    if (q) {
      navigate(`/dashboard/scan/${q}`);
      setSearchQuery('');
    }
  };

  const initials = user?.full_name
    ? user.full_name.split(' ').map((n) => n[0]).join('').toUpperCase()
    : 'U';

  return (
    <header className="top-bar">
      {/* Quick Scan Lookup */}
      <form onSubmit={handleSearch} className="topbar-search">
        <MagnifyingGlass size={16} color="var(--color-text-tertiary)" />
        <input
          type="text"
          placeholder="Search scan by ID…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          aria-label="Search scan by ID"
        />
      </form>

      {/* Dark Mode Toggle */}
      <button
        className="topbar-icon-btn"
        onClick={() => setIsDark(!isDark)}
        aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
        title={isDark ? 'Light mode' : 'Dark mode'}
      >
        {isDark ? <Sun size={20} weight="fill" /> : <Moon size={20} />}
      </button>

      {/* Notifications */}
      <button className="topbar-icon-btn" aria-label="Notifications">
        <Bell size={20} />
      </button>

      {/* User Info */}
      <div className="topbar-user">
        <div className="topbar-avatar">{initials}</div>
        <div className="topbar-user-info">
          <span className="topbar-user-name">{user?.full_name || 'User'}</span>
          <span className="topbar-user-role">{user?.role || ''}</span>
        </div>
      </div>

      {/* Logout */}
      <button
        className="btn btn-secondary"
        onClick={handleLogout}
        style={{ padding: '6px 12px', fontSize: '0.75rem' }}
      >
        <SignOut size={16} /> Sign Out
      </button>
    </header>
  );
};
