import React from 'react';
import { useNavigate } from 'react-router-dom';

const RoleSelection = () => {
    const navigate = useNavigate();

    return (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '80vh', gap: '2rem' }}>
            <h1 style={{ fontSize: '3rem', background: 'linear-gradient(to right, var(--primary), var(--accent))', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                Welcome to AMA Orders
            </h1>
            <p style={{ color: 'var(--text-muted)', fontSize: '1.2rem' }}>Select your role to get started</p>

            <div style={{ display: 'flex', gap: '2rem', flexWrap: 'wrap', justifyContent: 'center' }}>
                <button
                    className="glass-panel"
                    onClick={() => navigate('/maker')}
                    style={{
                        padding: '3rem',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        gap: '1rem',
                        cursor: 'pointer',
                        transition: 'transform 0.2s',
                        minWidth: '250px'
                    }}
                    onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                >
                    <span style={{ fontSize: '3rem' }}>📝</span>
                    <h2 style={{ color: 'var(--text-main)' }}>Order Maker</h2>
                    <p style={{ color: 'var(--text-muted)' }}>Create and assign orders</p>
                </button>

                <button
                    className="glass-panel"
                    onClick={() => navigate('/taker')}
                    style={{
                        padding: '3rem',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        gap: '1rem',
                        cursor: 'pointer',
                        transition: 'transform 0.2s',
                        minWidth: '250px'
                    }}
                    onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                    onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
                >
                    <span style={{ fontSize: '3rem' }}>📦</span>
                    <h2 style={{ color: 'var(--text-main)' }}>Order Taker</h2>
                    <p style={{ color: 'var(--text-muted)' }}>View and manage assignments</p>
                </button>
            </div>
        </div>
    );
};

export default RoleSelection;
