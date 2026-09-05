export function homeRouteForRole(role?: string | null): string {
  switch (role) {
    case 'ADMIN':
      return '/dashboard/admin/analytics';
    case 'QA_MANAGER':
      return '/dashboard';
    case 'INSPECTOR':
      return '/dashboard';
    case 'ECOM_LEAD':
      return '/dashboard/ecom/overview';
    case 'CITIZEN':
      return '/dashboard/citizen-notice';
    default:
      return '/dashboard';
  }
}
