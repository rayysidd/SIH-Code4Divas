import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  House, Package, Warning, Globe, ChartLine,
  Gear, Camera, ClockCounterClockwise,
  Users, Stack, Ticket, ClipboardText, FileText,
} from '@phosphor-icons/react';
import { useAuthStore } from '../store/authStore';

interface NavItem {
  to: string;
  icon: React.ElementType;
  label: string;
  section?: string;
}

function getNavItems(role: string): NavItem[] {
  const common: NavItem[] = [
    { to: '/dashboard', icon: House, label: 'Overview' },
  ];

  switch (role) {
    case 'ADMIN':
      return [
        ...common,
        { to: '/dashboard/admin/users', icon: Users, label: 'User Management', section: 'Administration' },
        { to: '/dashboard/admin/invite-codes', icon: Ticket, label: 'Invite Codes' },
        { to: '/dashboard/admin/rules-version', icon: FileText, label: 'Rules Version' },
        { to: '/dashboard/admin/audit-log', icon: ClipboardText, label: 'Audit Log' },
        { to: '/dashboard/admin/analytics', icon: ChartLine, label: 'District Analytics', section: 'Oversight' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings', section: 'System' },
      ];

    case 'INSPECTOR':
      return [
        ...common,
        { to: '/dashboard/scan/new', icon: Camera, label: 'New Scan', section: 'Operations' },
        { to: '/dashboard/products', icon: Package, label: 'Products' },
        { to: '/dashboard/violations', icon: Warning, label: 'Violations' },
        { to: '/dashboard/history', icon: ClockCounterClockwise, label: 'Scan History' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings', section: 'System' },
      ];

    case 'QA_MANAGER':
      return [
        ...common,
        { to: '/dashboard/products', icon: Package, label: 'Products', section: 'Operations' },
        { to: '/dashboard/analytics', icon: ChartLine, label: 'Analytics', section: 'Insights' },
        { to: '/dashboard/batch', icon: Stack, label: 'Batch Audit' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings', section: 'System' },
      ];

    case 'ECOM_LEAD':
      return [
        { to: '/dashboard/ecom/overview', icon: House, label: 'Overview' },
        { to: '/dashboard/ecommerce', icon: Globe, label: 'E-Commerce', section: 'Marketplace' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings', section: 'System' },
      ];

    case 'CITIZEN':
      return [
        { to: '/dashboard/citizen-notice', icon: Warning, label: 'Citizen Reporting' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings', section: 'System' },
      ];

    default:
      return [
        ...common,
        { to: '/dashboard/scan/new', icon: Camera, label: 'New Scan' },
        { to: '/dashboard/settings', icon: Gear, label: 'Settings' },
      ];
  }
}

export const Sidebar: React.FC = () => {
  const role = useAuthStore((s) => s.user?.role ?? 'INSPECTOR');
  const navItems = getNavItems(role);

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <span>🔍</span>
        <span>LabelLens</span>
      </div>
      <nav className="sidebar-nav" aria-label="Main navigation">
        {navItems.map((item, index) => {
          const showSection = item.section && (index === 0 || item.section !== navItems[index - 1].section);

          return (
            <React.Fragment key={item.to}>
              {showSection && (
                <div className="sidebar-section-label">{item.section}</div>
              )}
              <NavLink
                to={item.to}
                className={({ isActive }) => `sidebar-item ${isActive ? 'active' : ''}`}
                end={item.to === '/dashboard'}
              >
                <item.icon size={20} weight="regular" />
                <span>{item.label}</span>
              </NavLink>
            </React.Fragment>
          );
        })}
      </nav>
    </aside>
  );
};
