import React, { useState } from 'react';
import { Eye, EyeSlash, CircleNotch, User, Lock, EnvelopeSimple, IdentificationBadge, Info } from '@phosphor-icons/react';
import { useAuthStore } from '../store/authStore';
import { useNavigate, Link } from 'react-router-dom';

export const RegisterPage: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const { register, isLoading, error, clearError } = useAuthStore();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username.trim() || !password.trim() || !fullName.trim() || !email.trim()) return;

    try {
      const result = await register(
        username.trim(),
        password,
        fullName.trim(),
        email.trim(),
        inviteCode.trim()
      );
      
      setSuccessMessage(result.message);
      
      // Auto-redirect after showing the role assignment message
      setTimeout(() => {
        navigate('/dashboard', { replace: true });
      }, 4000);
    } catch {
      // Error is already set in the store
    }
  };

  const getEmailHint = (currentEmail: string) => {
    const domain = currentEmail.split('@')[1]?.toLowerCase();
    if (!domain) return null;
    
    if (['amazon.in', 'flipkart.com', 'meesho.com'].includes(domain)) {
      return "You'll get Platform Lead access";
    }
    
    if (!inviteCode.trim()) {
      return "You'll get Citizen access — ask your department for an officer code.";
    }
    
    return null;
  };

  const emailHint = getEmailHint(email);

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
          <h2>Create Account</h2>
          <p>Join the Compliance Network</p>
        </div>

        {successMessage ? (
          <div className="register-success-overlay fade-in">
            <div className="success-icon">✓</div>
            <h3>Registration Successful!</h3>
            <p>{successMessage}</p>
            <div className="redirect-hint">Redirecting to dashboard...</div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="login-form">
            {error && (
              <div className="login-error fade-in-up" role="alert">
                <span>{error}</span>
              </div>
            )}

            <div className="login-field">
              <label htmlFor="reg-fullname">Full Name</label>
              <div className="login-input-wrapper">
                <IdentificationBadge size={18} className="login-input-icon" weight="regular" />
                <input
                  id="reg-fullname"
                  type="text"
                  placeholder="John Doe"
                  value={fullName}
                  onChange={(e) => { setFullName(e.target.value); clearError(); }}
                  autoComplete="name"
                  autoFocus
                  disabled={isLoading}
                />
              </div>
            </div>

            <div className="login-field">
              <label htmlFor="reg-email">Email Address</label>
              <div className="login-input-wrapper">
                <EnvelopeSimple size={18} className="login-input-icon" weight="regular" />
                <input
                  id="reg-email"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); clearError(); }}
                  autoComplete="email"
                  disabled={isLoading}
                />
              </div>
              {emailHint && (
                <div className="register-hint fade-in">
                  <Info size={14} />
                  <span>{emailHint}</span>
                </div>
              )}
            </div>

            <div className="login-field">
              <label htmlFor="reg-username">Username</label>
              <div className="login-input-wrapper">
                <User size={18} className="login-input-icon" weight="regular" />
                <input
                  id="reg-username"
                  type="text"
                  placeholder="Choose a username"
                  value={username}
                  onChange={(e) => { setUsername(e.target.value); clearError(); }}
                  autoComplete="username"
                  disabled={isLoading}
                />
              </div>
            </div>

            <div className="login-field">
              <label htmlFor="reg-password">Password</label>
              <div className="login-input-wrapper">
                <Lock size={18} className="login-input-icon" weight="regular" />
                <input
                  id="reg-password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Create a password"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); clearError(); }}
                  autoComplete="new-password"
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

            <div className="login-field">
              <label htmlFor="reg-invite">Invite Code (Optional)</label>
              <div className="login-input-wrapper">
                <Lock size={18} className="login-input-icon" weight="regular" />
                <input
                  id="reg-invite"
                  type="text"
                  placeholder="e.g. INSP-12345678"
                  value={inviteCode}
                  onChange={(e) => { setInviteCode(e.target.value); clearError(); }}
                  disabled={isLoading}
                />
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary login-submit"
              disabled={isLoading || !username.trim() || !password.trim() || !fullName.trim() || !email.trim()}
            >
              {isLoading ? (
                <>
                  <CircleNotch size={18} className="spin" />
                  Registering…
                </>
              ) : (
                'Create Account'
              )}
            </button>
          </form>
        )}

        {!successMessage && (
          <div className="register-footer-link">
            Already have an account? <Link to="/login">Sign in</Link>
          </div>
        )}
      </div>
    </div>
  );
};
