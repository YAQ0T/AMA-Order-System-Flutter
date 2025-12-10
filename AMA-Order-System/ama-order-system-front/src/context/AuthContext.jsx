import React, { createContext, useContext, useState, useEffect } from 'react';
import { API_BASE_URL } from '../utils/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem('token'));
    const [loading, setLoading] = useState(true);

    console.log('AuthProvider initialized, loading:', loading, 'user:', user);

    useEffect(() => {
        console.log('AuthProvider useEffect running, token:', token);

        const verifySession = async () => {
            try {
                if (!token) {
                    setUser(null);
                    localStorage.removeItem('user');
                    return;
                }

                const response = await fetch(`${API_BASE_URL}/api/auth/me`, {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!response.ok) {
                    throw new Error('Session verification failed');
                }

                const data = await response.json();
                setUser(data.user);
                localStorage.setItem('user', JSON.stringify(data.user));
            } catch (error) {
                console.error('Error verifying session:', error);
                setUser(null);
                setToken(null);
                localStorage.removeItem('token');
                localStorage.removeItem('user');
            } finally {
                setLoading(false);
                console.log('AuthProvider loading set to false');
            }
        };

        verifySession();
    }, [token]);

    const login = async (username, password) => {
        try {
            const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password }),
            });

            const data = await response.json();
            if (!response.ok) {
                // Check if it's a pending approval error
                if (data.requiresApproval) {
                    throw new Error(data.error || 'Account pending approval');
                }
                throw new Error(data.error || 'Login failed');
            }

            setToken(data.token);
            setUser(data.user);
            localStorage.setItem('token', data.token);
            localStorage.setItem('user', JSON.stringify(data.user));
            return data; // Return data for pending approval check
        } catch (error) {
            console.error(error);
            throw error;
        }
    };

    const signup = async (username, password, role) => {
        try {
            const response = await fetch(`${API_BASE_URL}/api/auth/register`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password, role }),
            });

            const data = await response.json();
            if (!response.ok) throw new Error(data.error || 'Signup failed');
            return true;
        } catch (error) {
            console.error(error);
            throw error;
        }
    };

    const logout = () => {
        setUser(null);
        setToken(null);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
    };

    return (
        <AuthContext.Provider value={{ user, token, login, signup, logout, loading }}>
            {children}
        </AuthContext.Provider>
    );
};
