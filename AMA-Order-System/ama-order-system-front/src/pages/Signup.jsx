import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Signup = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [role, setRole] = useState('maker');
    const [error, setError] = useState('');
    const { signup } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        try {
            await signup(username, password, role);
            navigate('/login');
        } catch (err) {
            setError(err.message);
        }
    };

    return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '80vh' }}>
            <div className="glass-panel" style={{ padding: '2rem', width: '100%', maxWidth: '400px' }}>
                <h2 style={{ textAlign: 'center', marginBottom: '2rem' }}>Create Account</h2>

                {error && <div style={{ color: '#ef4444', marginBottom: '1rem', textAlign: 'center' }}>{error}</div>}

                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>Username</label>
                        <input
                            type="text"
                            className="input-field"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                        />
                    </div>

                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>Password</label>
                        <input
                            type="password"
                            className="input-field"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>I am a...</label>
                        <div style={{ display: 'flex', gap: '1rem' }}>
                            <label style={{ flex: 1, cursor: 'pointer' }}>
                                <input
                                    type="radio"
                                    name="role"
                                    value="maker"
                                    checked={role === 'maker'}
                                    onChange={(e) => setRole(e.target.value)}
                                    style={{ marginRight: '0.5rem' }}
                                />
                                Order Maker
                            </label>
                            <label style={{ flex: 1, cursor: 'pointer' }}>
                                <input
                                    type="radio"
                                    name="role"
                                    value="taker"
                                    checked={role === 'taker'}
                                    onChange={(e) => setRole(e.target.value)}
                                    style={{ marginRight: '0.5rem' }}
                                />
                                Order Taker
                            </label>
                            <label style={{ flex: 1, cursor: 'pointer' }}>
                                <input
                                    type="radio"
                                    name="role"
                                    value="accounter"
                                    checked={role === 'accounter'}
                                    onChange={(e) => setRole(e.target.value)}
                                    style={{ marginRight: '0.5rem' }}
                                />
                                Accounter
                            </label>
                        </div>
                    </div>

                    <button type="submit" className="btn-primary" style={{ marginTop: '1rem' }}>
                        Sign Up
                    </button>
                </form>

                <p style={{ marginTop: '1.5rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                    Already have an account? <Link to="/login" style={{ color: 'var(--primary)' }}>Log In</Link>
                </p>
                <p style={{ marginTop: '1rem', textAlign: 'center', fontSize: '0.9rem' }}>
                    <a href={`${window.location.origin}/install-employee-cert.html`} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--text-muted)', textDecoration: 'underline' }}>
                        📱 Install Employee Certificate
                    </a>
                </p>
            </div>
        </div>
    );
};

export default Signup;
