import React from 'react';

const PendingApproval = () => {
    return (
        <div className="container" style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '60vh',
            textAlign: 'center'
        }}>
            <div className="glass-panel" style={{
                padding: '3rem',
                maxWidth: '500px',
                textAlign: 'center'
            }}>
                <div style={{ fontSize: '4rem', marginBottom: '1rem' }}>⏳</div>
                <h1 style={{ marginBottom: '1rem', color: 'var(--primary)' }}>
                    Account Pending Approval
                </h1>
                <p style={{ color: 'var(--text-muted)', marginBottom: '2rem', lineHeight: '1.6' }}>
                    Your account has been created successfully, but it requires admin approval before you can log in.
                </p>
                <p style={{ color: 'var(--text-muted)', marginBottom: '2rem' }}>
                    Please contact your system administrator or wait for approval.
                </p>
                <div style={{
                    background: 'rgba(99, 102, 241, 0.1)',
                    padding: '1rem',
                    borderRadius: '8px',
                    marginTop: '2rem'
                }}>
                    <p style={{ margin: 0, fontSize: '0.9rem' }}>
                        💡 You'll be able to log in once an admin approves your account.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default PendingApproval;
