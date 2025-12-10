import React, { useState, useEffect } from 'react';
import { Outlet, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { API_BASE_URL } from '../utils/api';

import { useOrder } from '../context/OrderContext';

const Layout = () => {
    const { user, logout, token } = useAuth();
    const { fetchOrders, orderPagination } = useOrder();
    const [notifications, setNotifications] = useState([]);
    const [showNotifications, setShowNotifications] = useState(false);
    const unreadCount = notifications.filter(n => !n.isRead).length;
    const prevUnreadCountRef = React.useRef(0);
    const isFirstLoadRef = React.useRef(true);
    const notificationRef = React.useRef(null);

    const playNotificationSound = () => {
        try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);

            oscillator.type = 'sine';
            oscillator.frequency.setValueAtTime(500, audioContext.currentTime);
            oscillator.frequency.exponentialRampToValueAtTime(1000, audioContext.currentTime + 0.1);

            gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.00001, audioContext.currentTime + 0.5);

            oscillator.start();
            oscillator.stop(audioContext.currentTime + 0.5);
        } catch (e) {
            console.error("Audio play failed", e);
        }
    };

    useEffect(() => {
        if (isFirstLoadRef.current) {
            isFirstLoadRef.current = false;
            prevUnreadCountRef.current = unreadCount;
            return;
        }

        if (unreadCount > prevUnreadCountRef.current) {
            playNotificationSound();
        }
        prevUnreadCountRef.current = unreadCount;
    }, [unreadCount]);

    const fetchNotifications = async () => {
        if (!token) return;
        try {
            const res = await fetch(`${API_BASE_URL}/api/notifications`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setNotifications(data);
            }
        } catch (err) {
            console.error("Failed to fetch notifications", err);
        }
    };

    const subscribeToPush = async () => {
        if (!('serviceWorker' in navigator)) return;
        if (typeof Notification === 'undefined') {
            console.log('Notification API not available');
            return;
        }

        try {
            if (Notification.permission !== 'granted') {
                return;
            }

            const registration = await navigator.serviceWorker.ready;
            const subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: 'BPi7aQAQ7GVUmK_Kcj3DOwVZXWru297dmOiDPslJ4dlIKVc-YecqwQXXmgzbqxr8US5HVxPh8y-pgkrHmJdYj9M'
            });

            await fetch(`${API_BASE_URL}/api/notifications/subscribe`, {
                method: 'POST',
                body: JSON.stringify(subscription),
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });
        } catch (err) {
            console.error("Failed to subscribe to push", err);
        }
    };

    useEffect(() => {
        if (token) {
            const refreshData = () => {
                fetchNotifications();
            };

            refreshData();
            const interval = setInterval(refreshData, 5000); // Poll every 5 seconds

            // Subscribe if permission was previously granted without prompting the user
            if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
                subscribeToPush();
            }

            return () => clearInterval(interval);
        }
    }, [token, fetchOrders, orderPagination.limit, orderPagination.offset]);

    // Close notifications dropdown when clicking outside
    useEffect(() => {
        const handleClickOutside = (event) => {
            if (notificationRef.current && !notificationRef.current.contains(event.target)) {
                setShowNotifications(false);
            }
        };

        if (showNotifications) {
            document.addEventListener('mousedown', handleClickOutside);
        }

        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [showNotifications]);

    const markAsRead = async (id) => {
        try {
            await fetch(`${API_BASE_URL}/api/notifications/${id}/read`, {
                method: 'PUT',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            setNotifications(prev => prev.map(n => n.id === id ? { ...n, isRead: true } : n));
        } catch (err) {
            console.error("Failed to mark read", err);
        }
    };

    const markAllRead = async () => {
        try {
            await fetch(`${API_BASE_URL}/api/notifications/read-all`, {
                method: 'PUT',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
        } catch (err) {
            console.error("Failed to mark all read", err);
        }
    };

    return (
        <div className="min-h-screen flex flex-col">
            <nav className="glass-panel" style={{ margin: '1rem', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'relative', zIndex: 50 }}>
                <Link to="/" style={{ textDecoration: 'none', color: 'var(--text-main)', fontSize: '1.5rem', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span>📦</span> AMA Order System
                </Link>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
                    {user ? (
                        <>
                            {/* Notification Bell */}
                            <div ref={notificationRef} style={{ position: 'relative' }}>
                                <button
                                    onClick={() => setShowNotifications(!showNotifications)}
                                    style={{ background: 'none', border: 'none', fontSize: '1.5rem', cursor: 'pointer', position: 'relative' }}
                                >
                                    🔔
                                    {unreadCount > 0 && (
                                        <span style={{
                                            position: 'absolute',
                                            top: '-5px',
                                            right: '-5px',
                                            background: '#ef4444',
                                            color: 'white',
                                            fontSize: '0.7rem',
                                            width: '18px',
                                            height: '18px',
                                            borderRadius: '50%',
                                            display: 'flex',
                                            justifyContent: 'center',
                                            alignItems: 'center',
                                            fontWeight: 'bold'
                                        }}>
                                            {unreadCount}
                                        </span>
                                    )}
                                </button>

                                {/* Dropdown */}
                                {showNotifications && (
                                    <div className="glass-panel" style={{
                                        position: 'absolute',
                                        top: '180%',
                                        left: '-15px',
                                        width: '360px',
                                        maxHeight: '390px',
                                        overflowY: 'auto',
                                        padding: '0',
                                        zIndex: 1000,
                                        backgroundColor: '#0E1729',
                                        boxShadow: '0 10px 25px rgba(0,0,0,0.5)'
                                    }}>
                                        <div style={{ padding: '1rem', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <h3 style={{ margin: 0, fontSize: '1rem' }}>Notifications</h3>
                                            {unreadCount > 0 && (
                                                <button onClick={markAllRead} style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', fontSize: '0.8rem' }}>
                                                    Mark all read
                                                </button>
                                            )}
                                        </div>
                                        {notifications.length === 0 ? (
                                            <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                                                No notifications
                                            </div>
                                        ) : (
                                            <div>
                                                {notifications.map(note => (
                                                    <div
                                                        key={note.id}
                                                        onClick={() => !note.isRead && markAsRead(note.id)}
                                                        style={{
                                                            padding: '1rem',
                                                            borderBottom: '1px solid rgba(255,255,255,0.05)',
                                                            background: note.isRead ? 'transparent' : 'rgba(255,255,255,0.05)',
                                                            cursor: note.isRead ? 'default' : 'pointer',
                                                            transition: 'background 0.2s'
                                                        }}
                                                    >
                                                        <div style={{ fontSize: '0.9rem', marginBottom: '0.3rem' }}>{note.message}</div>
                                                        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{new Date(note.createdAt).toLocaleString()}</div>
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                <div style={{ textAlign: 'right' }}>
                                    <div style={{ fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                        {user.username}
                                        {user.role === 'admin' && (
                                            <span style={{
                                                background: '#ec4899',
                                                color: 'white',
                                                fontSize: '0.7rem',
                                                padding: '0.2rem 0.5rem',
                                                borderRadius: '8px'
                                            }}>
                                                ADMIN
                                            </span>
                                        )}
                                    </div>
                                    <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', textTransform: 'capitalize' }}>{user.role}</div>
                                </div>
                                {user.role === 'admin' && (
                                    <>
                                        <Link to="/admin" className="btn-primary" style={{ padding: '0.5rem 1rem', textDecoration: 'none' }}>
                                            👑 Admin Dashboard
                                        </Link>
                                        <Link to="/maker" className="btn-secondary" style={{ padding: '0.5rem 1rem', textDecoration: 'none' }}>
                                            📦 Maker Dashboard
                                        </Link>
                                    </>
                                )}
                                {user.role === 'maker' && (
                                    <Link to="/maker" className="btn-primary" style={{ padding: '0.5rem 1rem', textDecoration: 'none' }}>
                                        📦 Dashboard
                                    </Link>
                                )}
                                {user.role === 'taker' && (
                                    <Link to="/taker" className="btn-primary" style={{ padding: '0.5rem 1rem', textDecoration: 'none' }}>
                                        🛠 Dashboard
                                    </Link>
                                )}
                                {user.role === 'accounter' && (
                                    <Link to="/accounter" className="btn-primary" style={{ padding: '0.5rem 1rem', textDecoration: 'none' }}>
                                        🧾 Accounter
                                    </Link>
                                )}
                                <button onClick={logout} className="btn-secondary" style={{ padding: '0.5rem 1rem' }}>Logout</button>
                            </div>
                        </>
                    ) : (
                        <div style={{ display: 'flex', gap: '1rem' }}>
                            <Link to="/login" className="btn-secondary">Login</Link>
                            <Link to="/signup" className="btn-primary">Sign Up</Link>
                        </div>
                    )}
                </div>
            </nav>
            <main className="container fade-in" style={{ flex: 1 }}>
                <Outlet />
            </main>
        </div>
    );
};

export default Layout;
