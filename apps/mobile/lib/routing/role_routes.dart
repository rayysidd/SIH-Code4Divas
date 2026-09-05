String homeRouteForRole(String role) {
  switch (role) {
    case 'ADMIN':
      return '/admin/overview';
    case 'QA_MANAGER':
      return '/qa/overview';
    case 'ECOM_LEAD':
      return '/ecom/overview';
    case 'CITIZEN':
      return '/citizen';
    default:
      return '/'; // INSPECTOR
  }
}
