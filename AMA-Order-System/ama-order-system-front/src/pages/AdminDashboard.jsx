import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { API_BASE_URL } from '../utils/api';
import PrintableOrder from '../components/PrintableOrder';

const AdminDashboard = () => {
    const { token } = useAuth();
    const [activeTab, setActiveTab] = useState('overview');
    const [stats, setStats] = useState(null);
    const [users, setUsers] = useState([]);
    const [pendingUsers, setPendingUsers] = useState([]);
    const [orders, setOrders] = useState([]);
    const [logs, setLogs] = useState([]);
    const [auditLogs, setAuditLogs] = useState([]);
    const [loading, setLoading] = useState(false);
    const [expandedOrderId, setExpandedOrderId] = useState(null);
    const [takers, setTakers] = useState([]);
    const [newOrderTitle, setNewOrderTitle] = useState('');
    const [newOrderDescription, setNewOrderDescription] = useState('');
    const [newOrderItems, setNewOrderItems] = useState([{ name: '', quantity: 1 }]);
    const [newOrderTakers, setNewOrderTakers] = useState([]);
    const [newOrderCity, setNewOrderCity] = useState('نابلس');
    const cities = ['نابلس', 'الخليل', 'جنين', 'طولكرم', 'بديا', 'قلقيليا', 'رامالله', 'بيت لحم', 'الداخل'];
    const [editingOrderId, setEditingOrderId] = useState(null);
    const [editTitle, setEditTitle] = useState('');
    const [editDescription, setEditDescription] = useState('');
    const [editStatus, setEditStatus] = useState('pending');
    const [editItems, setEditItems] = useState([]);
    const [editTakers, setEditTakers] = useState([]);
    const [orderLogs, setOrderLogs] = useState({});
    const [logVisibility, setLogVisibility] = useState({});
    const [orderSearchTerm, setOrderSearchTerm] = useState('');
    const [orderDateFilter, setOrderDateFilter] = useState('');
    const [viewOrder, setViewOrder] = useState(null);

    // Archiving & Bulk Send State
    const [showArchived, setShowArchived] = useState(false);
    const [selectedArchivedOrders, setSelectedArchivedOrders] = useState([]);
    const [bulkSendCity, setBulkSendCity] = useState(null);
    const [showBulkSendModal, setShowBulkSendModal] = useState(false);
    const [bulkSendTakers, setBulkSendTakers] = useState([]);

    // Product Suggestions
    const [productSuggestions, setProductSuggestions] = useState([]);
    const [titleSuggestions, setTitleSuggestions] = useState([]);

    // Email editing
    const [editingEmailUserId, setEditingEmailUserId] = useState(null);
    const [editingEmailValue, setEditingEmailValue] = useState('');

    // Print State
    const [ordersToPrint, setOrdersToPrint] = useState([]);

    const fetchProductSuggestions = async (query) => {
        if (!query || query.length < 2) {
            setProductSuggestions([]);
            return;
        }
        try {
            const response = await fetch(`${API_BASE_URL}/api/items/suggestions?q=${encodeURIComponent(query)}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (response.ok) {
                const data = await response.json();
                setProductSuggestions(data);
            }
        } catch (error) {
            console.error('Failed to fetch suggestions', error);
        }
    };

    const fetchTitleSuggestions = async (query) => {
        if (!query || query.length < 1) {
            setTitleSuggestions([]);
            return;
        }
        try {
            const response = await fetch(`${API_BASE_URL}/api/orders/suggestions?q=${encodeURIComponent(query)}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (response.ok) {
                const data = await response.json();
                setTitleSuggestions(data);
            }
        } catch (error) {
            console.error('Failed to fetch title suggestions', error);
        }
    };

    // Start editing email
    const startEditingEmail = (user) => {
        setEditingEmailUserId(user.id);
        setEditingEmailValue(user.email || '');
    };

    // Save email
    const saveEmail = async (userId) => {
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/users/${userId}/email`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ email: editingEmailValue })
            });

            if (res.ok) {
                alert('Email updated successfully!');
                setEditingEmailUserId(null);
                setEditingEmailValue('');
                fetchUsers();
            } else {
                const data = await res.json();
                alert(data.error || 'Failed to update email');
            }
        } catch (err) {
            console.error('Failed to update email', err);
            alert('Failed to update email');
        }
    };

    // Fetch stats
    const fetchStats = async () => {
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/stats`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setStats(data);
            }
        } catch (err) {
            console.error('Failed to fetch stats', err);
        }
    };

    // Delete order
    const deleteOrder = async (orderId) => {
        if (!confirm('Are you sure you want to delete this order? This action cannot be undone.')) {
            return;
        }

        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/orders/${orderId}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (res.ok) {
                alert('Order deleted successfully');
                fetchOrders();
            } else {
                const data = await res.json();
                alert(data.error || 'Failed to delete order');
            }
        } catch (err) {
            console.error('Failed to delete order', err);
            alert('Failed to delete order');
        }
    };

    // Fetch all users
    const fetchUsers = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/users`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setUsers(data);
            }
        } catch (err) {
            console.error('Failed to fetch users', err);
        }
        setLoading(false);
    };

    // Fetch pending users
    const fetchPendingUsers = async () => {
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/users/pending`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setPendingUsers(data);
            }
        } catch (err) {
            console.error('Failed to fetch pending users', err);
        }
    };

    // Fetch all orders
    const fetchOrders = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/orders`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setOrders(data);
            }
        } catch (err) {
            console.error('Failed to fetch orders', err);
        }
        setLoading(false);
    };

    // Fetch activity logs
    const fetchLogs = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/logs?limit=50`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setLogs(data);
            }
        } catch (err) {
            console.error('Failed to fetch logs', err);
        }
        setLoading(false);
    };

    const fetchAuditLogs = async () => {
        setLoading(true);
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/logs/all?limit=300`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setAuditLogs(data);
            }
        } catch (err) {
            console.error('Failed to fetch audit logs', err);
        }
        setLoading(false);
    };

    // Fetch takers for assignment
    const fetchTakers = async () => {
        try {
            const res = await fetch(`${API_BASE_URL}/api/auth/takers`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setTakers(data);
            }
        } catch (err) {
            console.error('Failed to fetch takers', err);
        }
    };

    // Create order as admin
    const createOrder = async (isArchived = false) => {
        const payload = {
            title: newOrderTitle,
            description: newOrderDescription,
            items: newOrderItems,
            assignedTakerIds: newOrderTakers,
            city: newOrderCity,
            status: isArchived ? 'archived' : 'pending'
        };

        try {
            const res = await fetch(`${API_BASE_URL}/api/orders`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                setNewOrderTitle('');
                setNewOrderDescription('');
                setNewOrderItems([{ name: '', quantity: 1 }]);
                setNewOrderTakers([]);
                setNewOrderCity('نابلس');
                fetchOrders();
                alert('Order created successfully');
            } else {
                const data = await res.json();
                alert(data.error || 'Failed to create order');
            }
        } catch (err) {
            console.error('Failed to create order', err);
            alert('Failed to create order');
        }
    };

    // Start editing an order
    const startEditing = (order) => {
        setEditingOrderId(order.id);
        setEditTitle(order.title || '');
        setEditDescription(order.description || '');
        setEditStatus(order.status || 'pending');
        setEditItems(order.Items ? order.Items.map(item => ({ name: item.name, quantity: item.quantity })) : []);
        setEditTakers(order.AssignedTakers ? order.AssignedTakers.map(t => t.id) : []);
    };

    const saveEdit = async (orderId) => {
        const payload = {
            title: editTitle,
            description: editDescription,
            status: editStatus,
            items: editItems,
            assignedTakerIds: editTakers
        };

        try {
            const res = await fetch(`${API_BASE_URL}/api/orders/${orderId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                setEditingOrderId(null);
                setEditTitle('');
                setEditDescription('');
                setEditStatus('pending');
                setEditItems([]);
                setEditTakers([]);
                fetchOrders();
                alert('Order updated successfully');
            } else {
                const data = await res.json();
                alert(data.error || 'Failed to update order');
            }
        } catch (err) {
            console.error('Failed to update order', err);
            alert('Failed to update order');
        }
    };

    const toggleNewTaker = (id) => {
        setNewOrderTakers(prev => prev.includes(id) ? prev.filter(t => t !== id) : [...prev, id]);
    };

    const toggleEditTaker = (id) => {
        setEditTakers(prev => prev.includes(id) ? prev.filter(t => t !== id) : [...prev, id]);
    };

    const addNewItem = () => {
        setNewOrderItems(prev => [...prev, { name: '', quantity: 1 }]);
    };

    const removeNewItem = (index) => {
        setNewOrderItems(prev => prev.filter((_, i) => i !== index));
    };

    const updateNewItem = (index, field, value) => {
        setNewOrderItems(prev => prev.map((item, i) => i === index ? { ...item, [field]: value } : item));
    };

    const addEditItem = () => {
        setEditItems(prev => [...prev, { name: '', quantity: 1 }]);
    };

    const removeEditItem = (index) => {
        setEditItems(prev => prev.filter((_, i) => i !== index));
    };

    const updateEditItem = (index, field, value) => {
        setEditItems(prev => prev.map((item, i) => i === index ? { ...item, [field]: value } : item));
    };

    // Bulk Sending Handlers
    const handleBulkSelect = (orderId) => {
        setSelectedArchivedOrders(prev =>
            prev.includes(orderId) ? prev.filter(id => id !== orderId) : [...prev, orderId]
        );
    };

    const handleSelectAllCity = (cityOrders) => {
        const cityOrderIds = cityOrders.map(o => o.id);
        const allSelected = cityOrderIds.every(id => selectedArchivedOrders.includes(id));

        if (allSelected) {
            setSelectedArchivedOrders(prev => prev.filter(id => !cityOrderIds.includes(id)));
        } else {
            setSelectedArchivedOrders(prev => [...new Set([...prev, ...cityOrderIds])]);
        }
    };

    const initiateBulkSend = (city) => {
        setBulkSendCity(city);
        setBulkSendTakers([]);
        setShowBulkSendModal(true);
    };

    const toggleBulkTaker = (takerId) => {
        const id = Number(takerId);
        setBulkSendTakers(prev =>
            prev.includes(id) ? prev.filter(prevId => prevId !== id) : [...prev, id]
        );
    };

    const confirmBulkSend = async () => {
        if (bulkSendTakers.length === 0) {
            alert('Please select at least one taker.');
            return;
        }

        // Filter selected orders that belong to the current bulk send city
        const ordersToSend = orders
            .filter(o => o.status === 'archived' && o.city === bulkSendCity && selectedArchivedOrders.includes(o.id));

        const updatedOrders = [];

        for (const order of ordersToSend) {
            // Update each order
            try {
                const payload = {
                    title: order.title,
                    description: order.description,
                    status: 'pending',
                    items: order.Items,
                    assignedTakerIds: bulkSendTakers,
                    city: order.city,
                    skipEmail: true // Skip individual emails during bulk send
                };

                const response = await fetch(`${API_BASE_URL}/api/orders/${order.id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(payload)
                });

                if (response.ok) {
                    const updated = await response.json();
                    updatedOrders.push(updated);
                }
            } catch (err) {
                console.error(`Failed to update order ${order.id}`, err);
            }
        }

        // Send one consolidated email per taker
        if (updatedOrders.length > 0 && bulkSendTakers.length > 0) {
            try {
                await fetch(`${API_BASE_URL}/api/orders/bulk-email`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({
                        orderIds: updatedOrders.map(o => o.id),
                        takerIds: bulkSendTakers
                    })
                });
            } catch (err) {
                console.error('Failed to send bulk emails', err);
            }
        }

        setShowBulkSendModal(false);
        setBulkSendCity(null);
        setBulkSendTakers([]);
        setSelectedArchivedOrders(prev => prev.filter(id => !ordersToSend.map(o => o.id).includes(id)));
        fetchOrders();
        alert(`Sent ${ordersToSend.length} orders to takers!`);
    };

    const toggleOrderLogs = async (orderId) => {
        setLogVisibility(prev => ({ ...prev, [orderId]: !prev[orderId] }));

        if (orderLogs[orderId]?.logs || orderLogs[orderId]?.loading) return;

        setOrderLogs(prev => ({ ...prev, [orderId]: { logs: [], loading: true } }));
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/orders/${orderId}/logs`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                const sortedLogs = data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
                setOrderLogs(prev => ({ ...prev, [orderId]: { logs: sortedLogs, loading: false } }));
            } else {
                setOrderLogs(prev => ({ ...prev, [orderId]: { logs: [], loading: false, error: 'Failed to load logs' } }));
            }
        } catch (err) {
            console.error('Failed to load order logs', err);
            setOrderLogs(prev => ({ ...prev, [orderId]: { logs: [], loading: false, error: 'Failed to load logs' } }));
        }
    };

    // Approve user
    const approveUser = async (userId) => {
        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/users/${userId}/approve`, {
                method: 'PUT',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                alert('User approved successfully!');
                fetchPendingUsers();
                fetchUsers();
                fetchStats();
            }
        } catch (err) {
            console.error('Failed to approve user', err);
            alert('Failed to approve user');
        }
    };

    // Delete user
    const deleteUser = async (userId, username) => {
        if (!confirm(`Are you sure you want to delete user "${username}"? This action cannot be undone.`)) {
            return;
        }

        try {
            const res = await fetch(`${API_BASE_URL}/api/admin/users/${userId}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                alert('User deleted successfully!');
                fetchUsers();
                fetchStats();
            } else {
                const data = await res.json();
                alert(data.error || 'Failed to delete user');
            }
        } catch (err) {
            console.error('Failed to delete user', err);
            alert('Failed to delete user');
        }
    };

    useEffect(() => {
        fetchStats();
        fetchPendingUsers();
    }, []);

    useEffect(() => {
        if (activeTab === 'users') fetchUsers();
        else if (activeTab === 'orders') {
            fetchOrders();
            fetchTakers();
        }
        else if (activeTab === 'logs') fetchLogs();
        else if (activeTab === 'audit') fetchAuditLogs();
    }, [activeTab]);

    const getRoleBadgeColor = (role) => {
        switch (role) {
            case 'admin': return 'var(--primary)';
            case 'maker': return 'var(--accent)';
            case 'taker': return '#10b981';
            default: return 'var(--text-muted)';
        }
    };

    // Print Handlers
    const handlePrintOrder = (order) => {
        setOrdersToPrint([order]);
        setTimeout(() => {
            window.print();
            setOrdersToPrint([]);
        }, 100);
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'pending': return '#f59e0b';
            case 'in-progress': return '#3b82f6';
            case 'completed': return '#22c55e';
            case 'cancelled': return '#ef4444';
            default: return '#94a3b8';
        }
    };

    const filteredOrders = orders.filter(order => {
        // Exclude archived orders from active view
        if (order.status === 'archived') return false;

        const searchLower = orderSearchTerm.toLowerCase();
        const normalizedDate = new Date(order.createdAt).toISOString().slice(0, 10);
        const matchesDate = orderDateFilter ? normalizedDate === orderDateFilter : true;
        const matchesText =
            (order.title || '').toLowerCase().includes(searchLower) ||
            (order.description || '').toLowerCase().includes(searchLower) ||
            (order.Maker?.username || '').toLowerCase().includes(searchLower) ||
            (order.AssignedTakers || []).some(t => t.username.toLowerCase().includes(searchLower));

        return matchesText && matchesDate;
    });

    const renderEditForm = (order) => (
        <div style={{ display: 'grid', gap: '0.75rem' }}>
            <div>
                <label style={{ display: 'block', marginBottom: '0.35rem' }}>Title</label>
                <input className="input-field" value={editTitle} onChange={(e) => setEditTitle(e.target.value)} />
            </div>
            <div>
                <label style={{ display: 'block', marginBottom: '0.35rem' }}>Description</label>
                <textarea className="input-field" rows={3} value={editDescription} onChange={(e) => setEditDescription(e.target.value)} />
            </div>
            <div>
                <label style={{ display: 'block', marginBottom: '0.35rem' }}>Status</label>
                <select className="input-field" value={editStatus} onChange={(e) => setEditStatus(e.target.value)}>
                    <option value="pending">pending</option>
                    <option value="in-progress">in-progress</option>
                    <option value="completed">completed</option>
                    <option value="archived">archived</option>
                </select>
            </div>
            <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
                    <label>Items</label>
                    <button type="button" className="btn-secondary" onClick={addEditItem}>+ Add Item</button>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    {editItems.map((item, idx) => (
                        <div key={`edit-${idx}`} style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                            <input
                                className="input-field"
                                placeholder="Name"
                                value={item.name}
                                onChange={(e) => updateEditItem(idx, 'name', e.target.value)}
                                style={{ flex: 2 }}
                            />
                            <input
                                type="number"
                                className="input-field"
                                placeholder="Qty"
                                value={item.quantity}
                                onChange={(e) => updateEditItem(idx, 'quantity', parseInt(e.target.value) || 1)}
                                style={{ flex: 1 }}
                                min={1}
                            />
                            {editItems.length > 1 && (
                                <button type="button" className="btn-secondary" onClick={() => removeEditItem(idx)}>
                                    ✕
                                </button>
                            )}
                        </div>
                    ))}
                </div>
            </div>
            <div>
                <label style={{ display: 'block', marginBottom: '0.35rem' }}>Assign Takers</label>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                    {takers.map(taker => (
                        <button
                            key={taker.id}
                            type="button"
                            className={`btn-secondary ${editTakers.includes(taker.id) ? 'active' : ''}`}
                            onClick={() => toggleEditTaker(taker.id)}
                            style={{ borderColor: editTakers.includes(taker.id) ? 'var(--primary)' : undefined }}
                        >
                            {taker.username} (ID: {taker.id})
                        </button>
                    ))}
                    {takers.length === 0 && (
                        <span style={{ color: 'var(--text-muted)' }}>No takers available</span>
                    )}
                </div>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                <button className="btn-secondary" onClick={() => setEditingOrderId(null)}>Cancel</button>
                <button className="btn-primary" onClick={() => saveEdit(order.id)}>Save Changes</button>
            </div>
        </div>
    );

    const renderReadOnlyDetails = (order) => (
        <div style={{ display: 'grid', gap: '0.75rem' }}>
            <div style={{ marginBottom: '0.5rem', color: 'var(--text-muted)' }}>
                {order.description || 'No description provided.'}
            </div>
            <div>
                <strong>Items:</strong>
                <ul style={{ margin: '0.5rem 0 0 1rem', padding: 0 }}>
                    {(order.Items || []).map((item, index) => (
                        <li key={`${order.id}-${item.name}`} style={{ color: 'var(--text-muted)' }}>
                            {index + 1}. {item.name} - Qty: {item.quantity}
                        </li>
                    ))}
                    {(order.Items || []).length === 0 && (
                        <li style={{ color: 'var(--text-muted)' }}>No items listed</li>
                    )}
                </ul>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                <span>Created: {new Date(order.createdAt).toLocaleString()}</span>
                <span>Updated: {new Date(order.updatedAt).toLocaleString()}</span>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
                <button className="btn-secondary" onClick={() => startEditing(order)}>Edit Order</button>
                <button className="btn-secondary" onClick={() => handlePrintOrder(order)} style={{ borderColor: 'var(--primary)', color: 'var(--primary)' }}>🖨️ Print</button>
                <button className="btn-danger" onClick={() => deleteOrder(order.id)}>
                    Delete Order
                </button>
                <button className="btn-secondary" onClick={() => toggleOrderLogs(order.id)}>
                    {logVisibility[order.id] ? 'Hide Logs' : 'View Logs'}
                </button>
            </div>
            {logVisibility[order.id] && (
                <div className="glass-panel" style={{ padding: '0.75rem' }}>
                    <h4 style={{ marginTop: 0 }}>Change History</h4>
                    {orderLogs[order.id]?.loading && <p>Loading logs...</p>}
                    {orderLogs[order.id]?.error && <p style={{ color: 'var(--accent)' }}>{orderLogs[order.id].error}</p>}
                    {(orderLogs[order.id]?.logs || []).length === 0 && !orderLogs[order.id]?.loading && (
                        <p style={{ color: 'var(--text-muted)' }}>No logs recorded.</p>
                    )}
                    {(orderLogs[order.id]?.logs || []).map(log => (
                        <div key={log.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '0.35rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                            <div>
                                <div style={{ fontWeight: '500' }}>{log.newDescription}</div>
                                <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                    From: {log.oldDescription || 'N/A'}
                                </div>
                                <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                    By: {log.User?.username || 'System'}
                                </div>
                            </div>
                            <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                {new Date(log.createdAt).toLocaleString()}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );

    return (
        <div className="container fade-in">
            <h1 style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <span>👑</span> Admin Dashboard
            </h1>

            {/* Tabs */}
            <div style={{
                display: 'flex',
                gap: '1rem',
                marginBottom: '2rem',
                flexWrap: 'wrap'
            }}>
                {['overview', 'approvals', 'users', 'orders', 'logs', 'audit'].map(tab => (
                    <button
                        key={tab}
                        onClick={() => setActiveTab(tab)}
                        className={activeTab === tab ? 'btn-primary' : 'btn-secondary'}
                        style={{ textTransform: 'capitalize' }}
                    >
                        {tab}
                        {tab === 'approvals' && pendingUsers.length > 0 && (
                            <span style={{
                                marginLeft: '0.5rem',
                                background: '#ef4444',
                                padding: '0.2rem 0.5rem',
                                borderRadius: '12px',
                                fontSize: '0.8rem'
                            }}>
                                {pendingUsers.length}
                            </span>
                        )}
                    </button>
                ))}
            </div>

            {/* Overview Tab */}
            {activeTab === 'overview' && stats && (
                <div>
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                        gap: '1.5rem',
                        marginBottom: '2rem'
                    }}>
                        <div className="glass-panel" style={{ padding: '1.5rem' }}>
                            <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>👥</div>
                            <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--primary)' }}>
                                {stats.totalUsers}
                            </div>
                            <div style={{ color: 'var(--text-muted)' }}>Total Users</div>
                        </div>

                        <div className="glass-panel" style={{ padding: '1.5rem' }}>
                            <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>⏳</div>
                            <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#f59e0b' }}>
                                {stats.pendingApprovals}
                            </div>
                            <div style={{ color: 'var(--text-muted)' }}>Pending Approvals</div>
                        </div>

                        <div className="glass-panel" style={{ padding: '1.5rem' }}>
                            <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>📦</div>
                            <div style={{ fontSize: '2rem', fontWeight: 'bold', color: 'var(--accent)' }}>
                                {stats.totalOrders}
                            </div>
                            <div style={{ color: 'var(--text-muted)' }}>Total Orders</div>
                        </div>

                        <div className="glass-panel" style={{ padding: '1.5rem' }}>
                            <div style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🔄</div>
                            <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#22c55e' }}>
                                {stats.activeOrders}
                            </div>
                            <div style={{ color: 'var(--text-muted)' }}>Active Orders</div>
                        </div>
                    </div>

                    {/* Recent Activity */}
                    <div className="glass-panel" style={{ padding: '1.5rem' }}>
                        <h2 style={{ marginBottom: '1rem' }}>Recent Activity</h2>
                        {stats.recentActivity && stats.recentActivity.length > 0 ? (
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                                {stats.recentActivity.map(log => (
                                    <div key={log.id} style={{
                                        padding: '0.75rem',
                                        background: 'rgba(255,255,255,0.03)',
                                        borderRadius: '8px',
                                        display: 'flex',
                                        justifyContent: 'space-between',
                                        alignItems: 'center'
                                    }}>
                                        <div>
                                            <span style={{ fontWeight: '500' }}>
                                                {log.User?.username || 'System'}
                                            </span>
                                            {' '}
                                            <span style={{ color: 'var(--text-muted)' }}>
                                                {log.action.replace(/_/g, ' ')}
                                            </span>
                                        </div>
                                        <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                                            {new Date(log.createdAt).toLocaleString()}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <p style={{ color: 'var(--text-muted)' }}>No recent activity</p>
                        )}
                    </div>
                </div>
            )}

            {/* Pending Approvals Tab */}
            {activeTab === 'approvals' && (
                <div className="glass-panel" style={{ padding: '1.5rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>Pending User Approvals</h2>
                    {pendingUsers.length === 0 ? (
                        <p style={{ color: 'var(--text-muted)', textAlign: 'center', padding: '2rem' }}>
                            No pending approvals 🎉
                        </p>
                    ) : (
                        <div style={{ display: 'grid', gap: '1rem' }}>
                            {pendingUsers.map(user => (
                                <div key={user.id} className="glass-panel" style={{
                                    padding: '1rem',
                                    display: 'flex',
                                    justifyContent: 'space-between',
                                    alignItems: 'center'
                                }}>
                                    <div>
                                        <div style={{ fontWeight: 'bold', marginBottom: '0.25rem' }}>
                                            {user.username}
                                        </div>
                                        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                                            <span style={{
                                                padding: '0.25rem 0.75rem',
                                                borderRadius: '12px',
                                                fontSize: '0.85rem',
                                                background: getRoleBadgeColor(user.role),
                                                color: 'white'
                                            }}>
                                                {user.role}
                                            </span>
                                            <span style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>
                                                Registered: {new Date(user.createdAt).toLocaleDateString()}
                                            </span>
                                        </div>
                                    </div>
                                    <button
                                        onClick={() => approveUser(user.id)}
                                        className="btn-primary"
                                        style={{ padding: '0.5rem 1.5rem' }}
                                    >
                                        ✓ Approve
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}

            {/* Users Tab */}
            {activeTab === 'users' && (
                <div className="glass-panel" style={{ padding: '1.5rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>All Users</h2>
                    {loading ? (
                        <p>Loading...</p>
                    ) : (
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                                <thead>
                                    <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Username</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Email</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Role</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Status</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Joined</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {users.map(user => (
                                        <tr key={user.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                                            <td style={{ padding: '0.75rem' }}>{user.username}</td>
                                            <td style={{ padding: '0.75rem', fontSize: '0.9rem' }}>
                                                {editingEmailUserId === user.id ? (
                                                    <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                                                        <input
                                                            type="email"
                                                            className="input-field"
                                                            value={editingEmail}
                                                            onChange={(e) => setEditingEmail(e.target.value)}
                                                            placeholder="user@example.com"
                                                            style={{ padding: '0.35rem 0.5rem', fontSize: '0.85rem', minWidth: '200px' }}
                                                        />
                                                        <button
                                                            onClick={() => saveEmail(user.id)}
                                                            style={{
                                                                background: '#22c55e',
                                                                color: 'white',
                                                                border: 'none',
                                                                padding: '0.35rem 0.75rem',
                                                                borderRadius: '6px',
                                                                cursor: 'pointer',
                                                                fontSize: '0.85rem'
                                                            }}
                                                        >
                                                            ✓
                                                        </button>
                                                        <button
                                                            onClick={() => {
                                                                setEditingEmailUserId(null);
                                                                setEditingEmail('');
                                                            }}
                                                            style={{
                                                                background: '#6b7280',
                                                                color: 'white',
                                                                border: 'none',
                                                                padding: '0.35rem 0.75rem',
                                                                borderRadius: '6px',
                                                                cursor: 'pointer',
                                                                fontSize: '0.85rem'
                                                            }}
                                                        >
                                                            ✕
                                                        </button>
                                                    </div>
                                                ) : (
                                                    <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                                                        <span style={{ color: user.email ? 'var(--text)' : 'var(--text-muted)' }}>
                                                            {user.email || 'Not set'}
                                                        </span>
                                                        <button
                                                            onClick={() => startEditingEmail(user)}
                                                            style={{
                                                                background: 'transparent',
                                                                color: 'var(--primary)',
                                                                border: '1px solid var(--primary)',
                                                                padding: '0.25rem 0.5rem',
                                                                borderRadius: '4px',
                                                                cursor: 'pointer',
                                                                fontSize: '0.75rem'
                                                            }}
                                                        >
                                                            ✏️ Edit
                                                        </button>
                                                    </div>
                                                )}
                                            </td>
                                            <td style={{ padding: '0.75rem' }}>
                                                <span style={{
                                                    padding: '0.25rem 0.75rem',
                                                    borderRadius: '12px',
                                                    fontSize: '0.85rem',
                                                    background: getRoleBadgeColor(user.role),
                                                    color: 'white'
                                                }}>
                                                    {user.role}
                                                </span>
                                            </td>
                                            <td style={{ padding: '0.75rem' }}>
                                                {user.isApproved ? (
                                                    <span style={{ color: '#22c55e' }}>✓ Approved</span>
                                                ) : (
                                                    <span style={{ color: '#f59e0b' }}>⏳ Pending</span>
                                                )}
                                            </td>
                                            <td style={{ padding: '0.75rem', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                                {new Date(user.createdAt).toLocaleDateString()}
                                            </td>
                                            <td style={{ padding: '0.75rem' }}>
                                                {user.role !== 'admin' && (
                                                    <button
                                                        onClick={() => deleteUser(user.id, user.username)}
                                                        style={{
                                                            background: '#ef4444',
                                                            color: 'white',
                                                            border: 'none',
                                                            padding: '0.4rem 0.8rem',
                                                            borderRadius: '6px',
                                                            cursor: 'pointer',
                                                            fontSize: '0.85rem'
                                                        }}
                                                    >
                                                        Delete
                                                    </button>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            )}

            {/* Orders Tab */}
            {activeTab === 'orders' && (
                <div className="glass-panel" style={{ padding: '1.5rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>All Orders</h2>
                    <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1rem', flexWrap: 'wrap' }}>
                        <input
                            type="text"
                            className="input-field"
                            placeholder="Search by title, maker, or taker"
                            value={orderSearchTerm}
                            onChange={(e) => setOrderSearchTerm(e.target.value)}
                            style={{ width: '240px' }}
                        />
                        <input
                            type="date"
                            className="input-field"
                            value={orderDateFilter}
                            onChange={(e) => setOrderDateFilter(e.target.value)}
                            style={{ width: '180px' }}
                        />
                    </div>
                    <div className="glass-panel" style={{ padding: '1rem', marginBottom: '1.5rem' }}>
                        <h3>Order Creation</h3>
                        <p style={{ color: 'var(--text-muted)', marginBottom: '1rem' }}>
                            Admins can manage and edit any order here, but creating new orders is handled in the Maker Dashboard.
                            Use the button below to switch to the maker workspace when you need to add a new order.
                        </p>
                        <Link to="/maker" className="btn-primary" style={{ width: 'fit-content', textDecoration: 'none' }}>
                            Go to Maker Dashboard
                        </Link>
                    </div>

                    {loading ? (
                        <p>Loading...</p>
                    ) : (
                        <div style={{ display: 'grid', gap: '1rem' }}>
                            <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '1rem' }}>
                                <div style={{ display: 'flex', background: 'rgba(255,255,255,0.1)', borderRadius: '8px', padding: '0.25rem' }}>
                                    <button
                                        onClick={() => setShowArchived(false)}
                                        style={{
                                            background: !showArchived ? 'var(--primary)' : 'transparent',
                                            color: !showArchived ? 'white' : 'var(--text-muted)',
                                            border: 'none',
                                            padding: '0.5rem 1rem',
                                            borderRadius: '6px',
                                            cursor: 'pointer',
                                            fontWeight: !showArchived ? 'bold' : 'normal'
                                        }}
                                    >
                                        Active Orders
                                    </button>
                                    <button
                                        onClick={() => setShowArchived(true)}
                                        style={{
                                            background: showArchived ? 'var(--primary)' : 'transparent',
                                            color: showArchived ? 'white' : 'var(--text-muted)',
                                            border: 'none',
                                            padding: '0.5rem 1rem',
                                            borderRadius: '6px',
                                            cursor: 'pointer',
                                            fontWeight: showArchived ? 'bold' : 'normal'
                                        }}
                                    >
                                        📂 Archived Orders
                                    </button>
                                </div>
                            </div>

                            {showArchived ? (
                                <div style={{ display: 'grid', gap: '2rem' }}>
                                    {Object.entries(
                                        orders
                                            .filter(o => o.status === 'archived')
                                            .reduce((acc, order) => {
                                                const city = order.city || 'Unspecified';
                                                if (!acc[city]) acc[city] = [];
                                                acc[city].push(order);
                                                return acc;
                                            }, {})
                                    ).map(([city, cityOrders]) => {
                                        const selectedInCity = cityOrders.filter(o => selectedArchivedOrders.includes(o.id));
                                        return (
                                            <div key={city} className="glass-panel" style={{ padding: '1.5rem' }}>
                                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                                                    <h3 style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                                                        🏙️ {city} <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>({cityOrders.length})</span>
                                                    </h3>
                                                    <div style={{ display: 'flex', gap: '1rem' }}>
                                                        <button
                                                            className="btn-secondary"
                                                            onClick={() => handleSelectAllCity(cityOrders)}
                                                        >
                                                            {selectedInCity.length === cityOrders.length ? 'Deselect All' : 'Select All'}
                                                        </button>
                                                        <button
                                                            className="btn-primary"
                                                            disabled={selectedInCity.length === 0}
                                                            onClick={() => initiateBulkSend(city)}
                                                        >
                                                            Send Selected ({selectedInCity.length})
                                                        </button>
                                                    </div>
                                                </div>
                                                <div style={{ display: 'grid', gap: '1rem' }}>
                                                    {cityOrders.map(order => (
                                                        <div key={order.id} style={{
                                                            display: 'flex',
                                                            gap: '1rem',
                                                            alignItems: 'flex-start',
                                                            padding: '1rem',
                                                            background: 'rgba(255,255,255,0.03)',
                                                            borderRadius: '8px',
                                                            border: selectedArchivedOrders.includes(order.id) ? '1px solid var(--primary)' : '1px solid transparent'
                                                        }}>
                                                            <input
                                                                type="checkbox"
                                                                checked={selectedArchivedOrders.includes(order.id)}
                                                                onChange={() => handleBulkSelect(order.id)}
                                                                style={{ width: '1.2rem', height: '1.2rem', marginTop: '0.35rem' }}
                                                            />
                                                            <div style={{ flex: 1, display: 'grid', gap: '0.5rem' }}>
                                                                <div style={{ fontWeight: 'bold' }}>{order.title || 'Untitled'}</div>
                                                                <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                                                    {order.Items?.length || 0} items • Created {new Date(order.createdAt).toLocaleDateString()}
                                                                </div>
                                                                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                                                                    <button className="btn-secondary" onClick={() => setViewOrder(order)}>View</button>
                                                                    <button className="btn-secondary" onClick={() => startEditing(order)}>Edit</button>
                                                                    <button className="btn-secondary" onClick={() => handlePrintOrder(order)} style={{ borderColor: 'var(--primary)', color: 'var(--primary)' }}>🖨️ Print</button>
                                                                    <button className="btn-danger" onClick={() => deleteOrder(order.id)}>Delete</button>
                                                                </div>
                                                                {editingOrderId === order.id && (
                                                                    <div className="glass-panel" style={{ padding: '1rem' }}>
                                                                        {renderEditForm(order)}
                                                                    </div>
                                                                )}
                                                            </div>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            ) : (
                                filteredOrders.map(order => {
                                    const isExpanded = expandedOrderId === order.id;
                                    return (
                                        <div key={order.id} className="glass-panel" style={{ padding: '1rem' }}>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem', gap: '1rem', alignItems: 'center' }}>
                                                <div>
                                                    <span style={{ fontWeight: 'bold' }}>Order #{order.id}</span>
                                                    {' - '}
                                                    <span style={{ color: 'var(--text-muted)' }}>
                                                        by {order.Maker?.username}
                                                    </span>
                                                </div>
                                                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                                                    <span style={{
                                                        padding: '0.25rem 0.75rem',
                                                        borderRadius: '12px',
                                                        fontSize: '0.85rem',
                                                        background: getStatusColor(order.status),
                                                        color: 'white'
                                                    }}>
                                                        {order.status}
                                                    </span>
                                                    <button
                                                        className="btn-secondary"
                                                        onClick={() => setViewOrder(order)}
                                                    >
                                                        View
                                                    </button>
                                                    <button
                                                        className="btn-secondary"
                                                        onClick={() => setExpandedOrderId(isExpanded ? null : order.id)}
                                                    >
                                                        {isExpanded ? 'Hide Details' : 'View Details'}
                                                    </button>
                                                </div>
                                            </div>
                                            <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                                {order.Items?.length || 0} items • Created {new Date(order.createdAt).toLocaleDateString()}
                                            </div>
                                            {
                                                order.AssignedTakers && order.AssignedTakers.length > 0 && (
                                                    <div style={{ marginTop: '0.5rem', fontSize: '0.9rem' }}>
                                                        Assigned to: {order.AssignedTakers.map(t => t.username).join(', ')}
                                                    </div>
                                                )
                                            }

                                            {isExpanded && (
                                                <div style={{ marginTop: '0.75rem', paddingTop: '0.75rem', borderTop: '1px solid var(--glass-border)' }}>
                                                    {editingOrderId === order.id ? renderEditForm(order) : renderReadOnlyDetails(order)}
                                                </div>
                                            )}
                                        </div >
                                    );
                                })
                            )}
                        </div>
                    )}
                </div>
            )}

            {/* Logs Tab */}
            {
                activeTab === 'logs' && (
                    <div className="glass-panel" style={{ padding: '1.5rem' }}>
                        <h2 style={{ marginBottom: '1rem' }}>Activity Logs</h2>
                        {loading ? (
                            <p>Loading...</p>
                        ) : (
                            <div style={{ overflowX: 'auto' }}>
                                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
                                    <thead>
                                        <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
                                            <th style={{ padding: '0.75rem', textAlign: 'left' }}>Time</th>
                                            <th style={{ padding: '0.75rem', textAlign: 'left' }}>User</th>
                                            <th style={{ padding: '0.75rem', textAlign: 'left' }}>Action</th>
                                            <th style={{ padding: '0.75rem', textAlign: 'left' }}>Details</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {logs.map(log => (
                                            <tr key={log.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                                                <td style={{ padding: '0.75rem', color: 'var(--text-muted)' }}>
                                                    {new Date(log.createdAt).toLocaleString()}
                                                </td>
                                                <td style={{ padding: '0.75rem' }}>
                                                    {log.User?.username || 'System'}
                                                </td>
                                                <td style={{ padding: '0.75rem' }}>
                                                    {log.action.replace(/_/g, ' ')}
                                                </td>
                                                <td style={{ padding: '0.75rem', color: 'var(--text-muted)' }}>
                                                    {log.details ? JSON.stringify(log.details).substring(0, 50) : '-'}
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </div>
                )
            }

            {/* Audit Tab */}
            {activeTab === 'audit' && (
                <div className="glass-panel" style={{ padding: '1.5rem' }}>
                    <h2 style={{ marginBottom: '1rem' }}>Full Audit Trail</h2>
                    {loading ? (
                        <p>Loading...</p>
                    ) : auditLogs.length === 0 ? (
                        <p style={{ color: 'var(--text-muted)' }}>No audit entries yet.</p>
                    ) : (
                        <div style={{ overflowX: 'auto' }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
                                <thead>
                                    <tr style={{ borderBottom: '1px solid var(--glass-border)' }}>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Time</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Type</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>User</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Target</th>
                                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Details</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {auditLogs.map((log, idx) => (
                                        <tr key={idx} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                                            <td style={{ padding: '0.75rem', whiteSpace: 'nowrap' }}>{new Date(log.createdAt).toLocaleString()}</td>
                                            <td style={{ padding: '0.75rem', textTransform: 'capitalize' }}>{log.type === 'order_change' ? 'Order Change' : log.action?.replace(/_/g, ' ') || log.type}</td>
                                            <td style={{ padding: '0.75rem' }}>{log.user?.username || 'System'}</td>
                                            <td style={{ padding: '0.75rem' }}>
                                                {log.targetType === 'order' || log.type === 'order_change'
                                                    ? `Order #${log.targetId || log.details?.order?.id || ''}`
                                                    : (log.targetType || '-')}
                                            </td>
                                            <td style={{ padding: '0.75rem', maxWidth: '500px' }}>
                                                <div style={{ color: 'var(--text-main)' }}>{log.description}</div>
                                                {log.details?.old && (
                                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Old: {log.details.old}</div>
                                                )}
                                                {log.details?.new && (
                                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>New: {log.details.new}</div>
                                                )}
                                                {log.details?.message && (
                                                    <div style={{ color: 'var(--accent)', fontSize: '0.85rem' }}>Error: {log.details.message}</div>
                                                )}
                                                {Array.isArray(log.details?.assignedTakerNames) && log.details.assignedTakerNames.length > 0 && (
                                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                                        Assigned to: {log.details.assignedTakerNames.join(', ')}
                                                    </div>
                                                )}
                                                {Array.isArray(log.details?.items) && log.details.items.length > 0 && (
                                                    <div style={{ marginTop: '0.4rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                                                        Items: {log.details.items.map(i => `${i.name} (x${i.quantity}${i.price ? `, ${i.price}` : ''})`).join(', ')}
                                                    </div>
                                                )}
                                                {Array.isArray(log.details?.changes) && log.details.changes.length > 0 && (
                                                    <div style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>Changes: {log.details.changes.join(', ')}</div>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            )}

            {/* Order View Modal */}
            {viewOrder && (
                <div style={{
                    position: 'fixed',
                    inset: 0,
                    background: 'rgba(0,0,0,0.8)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    zIndex: 1100,
                    padding: '1rem'
                }}>
                    <div className="glass-panel" style={{ width: '600px', maxWidth: '95vw', maxHeight: '85vh', overflowY: 'auto', padding: '1.5rem' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                            <h2 style={{ margin: 0 }}>Order #{viewOrder.id}</h2>
                            <button className="btn-secondary" onClick={() => setViewOrder(null)}>Close</button>
                        </div>
                        <div style={{ display: 'grid', gap: '0.75rem' }}>
                            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
                                <span style={{
                                    padding: '0.25rem 0.75rem',
                                    borderRadius: '12px',
                                    fontSize: '0.9rem',
                                    background: getStatusColor(viewOrder.status),
                                    color: 'white'
                                }}>
                                    {viewOrder.status}
                                </span>
                                <span style={{ color: 'var(--text-muted)' }}>City: {viewOrder.city || 'Unspecified'}</span>
                                <span style={{ color: 'var(--text-muted)' }}>Maker: {viewOrder.Maker?.username || 'Unknown'}</span>
                            </div>
                            <div>
                                <strong>Description:</strong>
                                <p style={{ marginTop: '0.35rem', color: 'var(--text-muted)' }}>
                                    {viewOrder.description || 'No description provided.'}
                                </p>
                            </div>
                            <div>
                                <strong>Items:</strong>
                                <ul style={{ margin: '0.5rem 0 0 1rem', padding: 0 }}>
                                    {(viewOrder.Items || []).map((item, index) => (
                                        <li key={`${viewOrder.id}-${item.name}`} style={{ color: 'var(--text-muted)' }}>
                                            {index + 1}. {item.name} - Qty: {item.quantity}
                                        </li>
                                    ))}
                                    {(viewOrder.Items || []).length === 0 && (
                                        <li style={{ color: 'var(--text-muted)' }}>No items listed</li>
                                    )}
                                </ul>
                            </div>
                            <div>
                                <strong>Assigned Takers:</strong>
                                <div style={{ marginTop: '0.35rem', color: 'var(--text-muted)' }}>
                                    {(viewOrder.AssignedTakers || []).length > 0
                                        ? viewOrder.AssignedTakers.map(t => t.username).join(', ')
                                        : 'No takers assigned'}
                                </div>
                            </div>
                            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                                <span>Created: {new Date(viewOrder.createdAt).toLocaleString()}</span>
                                <span>Updated: {new Date(viewOrder.updatedAt).toLocaleString()}</span>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Bulk Send Modal */}
            {showBulkSendModal && (
                <div style={{
                    position: 'fixed',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0,0,0,0.8)',
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    zIndex: 1000
                }}>
                    <div className="glass-panel" style={{ width: '500px', padding: '2rem', maxHeight: '80vh', overflowY: 'auto' }}>
                        <h2>Bulk Send Orders - {bulkSendCity}</h2>
                        <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem' }}>
                            Select takers to assign to the selected orders.
                        </p>

                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem', marginBottom: '2rem' }}>
                            {takers.map(taker => (
                                <button
                                    key={taker.id}
                                    onClick={() => toggleBulkTaker(taker.id)}
                                    className={`btn-secondary ${bulkSendTakers.includes(taker.id) ? 'active' : ''}`}
                                    style={{
                                        borderColor: bulkSendTakers.includes(taker.id) ? 'var(--primary)' : 'var(--glass-border)',
                                        background: bulkSendTakers.includes(taker.id) ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                    }}
                                >
                                    {taker.username}
                                </button>
                            ))}
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                            <button
                                className="btn-secondary"
                                onClick={() => setShowBulkSendModal(false)}
                            >
                                Cancel
                            </button>
                            <button
                                className="btn-primary"
                                onClick={confirmBulkSend}
                                disabled={bulkSendTakers.length === 0}
                            >
                                Confirm & Send
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Printable Orders */}
            <PrintableOrder orders={ordersToPrint} />
        </div >
    );
};

export default AdminDashboard;
