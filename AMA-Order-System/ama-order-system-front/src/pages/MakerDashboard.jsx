
import React, { useState, useMemo } from 'react';
import { useOrder } from '../context/OrderContext';
import { useAuth } from '../context/AuthContext';
import { API_BASE_URL } from '../utils/api';
import PrintableOrder from '../components/PrintableOrder';

// Simple Modal Component
const ConfirmModal = ({ isOpen, onClose, onConfirm, title, message }) => {
    if (!isOpen) return null;
    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: 'rgba(0,0,0,0.7)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            zIndex: 1000
        }}>
            <div className="glass-panel" style={{ padding: '2rem', maxWidth: '400px', width: '90%' }}>
                <h3 style={{ marginBottom: '1rem' }}>{title}</h3>
                <p style={{ marginBottom: '1.5rem', color: 'var(--text-muted)' }}>{message}</p>
                <div style={{ display: 'flex', gap: '1rem', justifyContent: 'flex-end' }}>
                    <button className="btn-secondary" onClick={onClose}>Cancel</button>
                    <button className="btn-danger" onClick={onConfirm}>Delete</button>
                </div>
            </div>
        </div>
    );
};

const MakerDashboard = () => {
    const { users, createOrder, orders, updateOrderDetails, deleteOrder, updateOrderStatus, orderPagination, fetchOrders } = useOrder();
    const { token } = useAuth();
    const [title, setTitle] = useState('');
    const [note, setNote] = useState('');
    const [city, setCity] = useState('نابلس');
    const [items, setItems] = useState([{ name: '', quantity: 1, price: '' }]);
    const [selectedTakers, setSelectedTakers] = useState([]);
    const [selectedAccounter, setSelectedAccounter] = useState(null);
    const [showSuccess, setShowSuccess] = useState(false);

    // Auto-refresh orders every 15 seconds


    // Delete Modal State
    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [orderToDelete, setOrderToDelete] = useState(null);

    // ERP Confirmation Modal State
    const [showErpModal, setShowErpModal] = useState(false);
    const [orderToErp, setOrderToErp] = useState(null);

    const handleDeleteClick = (order) => {
        setOrderToDelete(order);
        setShowDeleteModal(true);
    };

    const confirmDelete = async () => {
        if (orderToDelete) {
            await deleteOrder(orderToDelete.id);
            setShowDeleteModal(false);
            setOrderToDelete(null);
        }
    };

    const handleErpClick = (order) => {
        setOrderToErp(order);
        setShowErpModal(true);
    };

    const confirmErp = async () => {
        if (orderToErp) {
            await updateOrderStatus(orderToErp.id, 'entered_erp');
            setShowErpModal(false);
            setOrderToErp(null);
            fetchOrders({
                limit,
                offset: currentOffset,
                status: orderFilter === 'all' ? undefined : orderFilter,
                search: debouncedSearch || undefined
            });
        }
    };

    // Edit State
    const [editingOrderId, setEditingOrderId] = useState(null);
    const [editTitle, setEditTitle] = useState('');
    const [editCity, setEditCity] = useState('');
    const [editItems, setEditItems] = useState([]);
    const [editSelectedTakers, setEditSelectedTakers] = useState([]);
    const [editAccounter, setEditAccounter] = useState(null);
    const [editStatus, setEditStatus] = useState('');
    const [expandedHistoryId, setExpandedHistoryId] = useState(null);

    const [searchTerm, setSearchTerm] = useState('');
    const [searchDate, setSearchDate] = useState('');
    const [debouncedSearch, setDebouncedSearch] = useState('');
    const [currentOffset, setCurrentOffset] = useState(orderPagination.offset || 0);

    // Archiving & Bulk Send State
    const [orderFilter, setOrderFilter] = useState('active');
    const [selectedArchivedOrders, setSelectedArchivedOrders] = useState([]); // Array of order IDs
    const [bulkSendCity, setBulkSendCity] = useState(null); // City currently being bulk sent
    const [showBulkSendModal, setShowBulkSendModal] = useState(false);
    const [bulkSendTakers, setBulkSendTakers] = useState([]);
    const [bulkSendAccounter, setBulkSendAccounter] = useState(null);

    // Print State
    const [ordersToPrint, setOrdersToPrint] = useState([]);

    // Product & Title Suggestions
    const [productSuggestions, setProductSuggestions] = useState([]);
    const [titleSuggestions, setTitleSuggestions] = useState([]);

    const limit = orderPagination.limit || 20;

    React.useEffect(() => {
        const timer = setTimeout(() => setDebouncedSearch(searchTerm.trim()), 300);
        return () => clearTimeout(timer);
    }, [searchTerm]);

    // Auto-refresh orders every 15 seconds
    React.useEffect(() => {
        fetchOrders({
            limit,
            offset: currentOffset,
            status: orderFilter === 'all' ? undefined : orderFilter,
            search: debouncedSearch || undefined
        });

        const interval = setInterval(() => {
            fetchOrders({
                limit,
                offset: currentOffset,
                status: orderFilter === 'all' ? undefined : orderFilter,
                search: debouncedSearch || undefined
            });
        }, 15000);
        return () => clearInterval(interval);
    }, [fetchOrders, limit, currentOffset, orderFilter, debouncedSearch]);

    const filterButtonStyle = {
        padding: '0.35rem 0.75rem',
        fontSize: '0.9rem'
    };

    const fetchProductSuggestions = async (query) => {
        if (!query || query.length < 2) {
            setProductSuggestions([]);
            return;
        }
        try {
            const response = await fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:6001'}/api/items/suggestions?q=${encodeURIComponent(query)}`);
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
            const response = await fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:6001'}/api/orders/suggestions?q=${encodeURIComponent(query)}`, {
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

    const cities = ['نابلس', 'الخليل', 'جنين', 'طولكرم', 'بديا', 'قلقيليا', 'رامالله', 'بيت لحم', 'الداخل'];

    const handleAddItem = () => {
        setItems([...items, { name: '', quantity: 1, price: '' }]);
    };

    const handleRemoveItem = (index) => {
        setItems(items.filter((_, i) => i !== index));
    };

    const findDuplicateProductName = (products) => {
        const seenNames = new Map();

        for (const product of products) {
            const normalized = (product.name || '').trim().toLowerCase();

            if (!normalized) continue;

            if (seenNames.has(normalized)) {
                return seenNames.get(normalized) || product.name.trim();
            }

            seenNames.set(normalized, (product.name || '').trim());
        }

        return null;
    };

    const sanitizeItemList = (productList) => {
        const cleaned = productList
            .map(item => ({
                name: (item.name || '').trim(),
                quantity: Number(item.quantity),
                price: item.price === '' || item.price === null || item.price === undefined ? '' : Number(item.price)
            }))
            // Drop rows that are completely empty
            .filter(item => item.name !== '' || Number.isFinite(item.quantity));

        for (const item of cleaned) {
            if (!item.name || !Number.isFinite(item.quantity) || item.quantity <= 0) {
                return { valid: false, items: cleaned };
            }
            item.quantity = Math.round(item.quantity);
        }

        return { valid: true, items: cleaned };
    };

    const handleItemChange = (index, field, value) => {
        const newItems = [...items];
        if (field === 'price') {
            newItems[index][field] = value === '' ? '' : Number(value);
        } else {
            newItems[index][field] = value;
        }
        setItems(newItems);
    };

    const handleSubmit = async (e, isArchived = false) => {
        e.preventDefault();

        const { valid: itemsValid, items: cleanedItems } = sanitizeItemList(items);
        if (!itemsValid || cleanedItems.length === 0) {
            alert('Please enter at least one item with a valid quantity.');
            return;
        }

        const duplicateProduct = findDuplicateProductName(cleanedItems);
        if (duplicateProduct) {
            alert(`Duplicate product name found: ${duplicateProduct}\nاسم المنتج مكرر: ${duplicateProduct}`);
            return;
        }

        const validTakers = selectedTakers.map(id => Number(id)).filter(id => id > 0);

        if (!isArchived && validTakers.length === 0) {
            alert('Please assign at least one taker to the order.');
            return;
        }

        const payload = {
            description: note,
            title,
            items: cleanedItems,
            city,
            status: isArchived ? 'archived' : 'pending',
            accounterId: selectedAccounter || null
        };

        const success = await createOrder(payload, validTakers);
        if (success) {
            setTitle('');
            setNote('');
            setCity('نابلس');
            setItems([{ name: '', quantity: 1, price: '' }]);
            setSelectedTakers([]);
            setSelectedAccounter(null);
            setShowSuccess(true);
            setTimeout(() => setShowSuccess(false), 3000);
        }
    };

    const handleUpdate = async (orderId) => {
        const { valid: itemsValid, items: cleanedItems } = sanitizeItemList(editItems);
        if (!itemsValid || cleanedItems.length === 0) {
            alert('Please enter at least one item with a valid quantity.');
            return;
        }

        const duplicateProduct = findDuplicateProductName(cleanedItems);
        if (duplicateProduct) {
            alert(`Duplicate product name found: ${duplicateProduct}\nاسم المنتج مكرر: ${duplicateProduct}`);
            return;
        }

        const success = await updateOrderDetails(orderId, {
            title: editTitle,
            city: editCity,
            items: cleanedItems,
            assignedTakerIds: editSelectedTakers,
            accounterId: editAccounter || null,
            status: editStatus
        });
        if (success) {
            setEditingOrderId(null);
            setEditTitle('');
            setEditCity('');
            setEditItems([]);
            setEditSelectedTakers([]);
            setEditAccounter(null);
            setEditStatus('');
        }
    };

    const startEditing = (order) => {
        setEditingOrderId(order.id);
        setEditTitle(order.title || '');
        setEditCity(order.city || 'نابلس');
        setEditItems(order.Items ? order.Items.map(i => ({ name: i.name, quantity: i.quantity, price: i.price ?? '' })) : []);
        setEditSelectedTakers(order.AssignedTakers ? order.AssignedTakers.map(t => t.id) : []);
        setEditAccounter(order.Accounter?.id || null);
        setEditStatus(order.status || 'pending');
    };

    const toggleTaker = (takerId) => {
        const id = Number(takerId);
        if (!id) return;

        setSelectedTakers(prev =>
            prev.includes(id)
                ? prev.filter(prevId => prevId !== id)
                : [...prev, id]
        );
    };

    const handleEditAddItem = () => {
        setEditItems([...editItems, { name: '', quantity: 1, price: '' }]);
    };

    const handleEditRemoveItem = (index) => {
        setEditItems(editItems.filter((_, i) => i !== index));
    };

    const handleEditItemChange = (index, field, value) => {
        const newItems = [...editItems];
        if (field === 'price') {
            newItems[index][field] = value === '' ? '' : Number(value);
        } else {
            newItems[index][field] = value;
        }
        setEditItems(newItems);
    };

    const toggleEditTaker = (takerId) => {
        setEditSelectedTakers(prev =>
            prev.includes(takerId)
                ? prev.filter(id => id !== takerId)
                : [...prev, takerId]
        );
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
        setBulkSendAccounter(null);
        setShowBulkSendModal(true);
    };

    const toggleBulkTaker = (takerId) => {
        const id = Number(takerId);
        setBulkSendTakers(prev =>
            prev.includes(id) ? prev.filter(prevId => prevId !== id) : [...prev, id]
        );
    };

    const toggleBulkAccounter = (accounterId) => {
        const id = Number(accounterId);
        setBulkSendAccounter(prev => prev === id ? null : id);
    };

    const resetBulkSendState = () => {
        setShowBulkSendModal(false);
        setBulkSendCity(null);
        setBulkSendTakers([]);
        setBulkSendAccounter(null);
    };

    const confirmBulkSend = async () => {
        if (bulkSendTakers.length === 0) {
            alert('Please select at least one taker.');
            return;
        }

        const availableAccounters = users.filter(u => u.role === 'accounter');
        if (availableAccounters.length > 0 && !bulkSendAccounter) {
            alert('Please select an accounter to handle these orders.');
            return;
        }

        // Filter selected orders that belong to the current bulk send city
        const ordersToSend = orders
            .filter(o => o.status === 'archived' && o.city === bulkSendCity && selectedArchivedOrders.includes(o.id));

        const updatedOrderIds = [];

        for (const order of ordersToSend) {
            const success = await updateOrderDetails(order.id, {
                status: 'pending',
                assignedTakerIds: bulkSendTakers,
                skipEmail: true, // Avoid sending separate emails per order during bulk send
                accounterId: bulkSendAccounter || null
            });

            if (success) {
                updatedOrderIds.push(order.id);
            }
        }

        // Send one consolidated email per taker
        if (updatedOrderIds.length > 0 && bulkSendTakers.length > 0) {
            try {
                await fetch(`${API_BASE_URL}/api/orders/bulk-email`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({
                        orderIds: updatedOrderIds,
                        takerIds: bulkSendTakers
                    })
                });
            } catch (err) {
                console.error('Failed to send bulk emails', err);
            }
        }

        setSelectedArchivedOrders(prev => prev.filter(id => !ordersToSend.map(o => o.id).includes(id)));
        resetBulkSendState();
        alert(`Sent ${ordersToSend.length} orders to takers!`);
    };

    // Filter Orders - Now mostly server-side, but we keep search/date filtering here for now
    // Note: Search should ideally be server-side too for correct pagination with search, 
    // but for now we focus on status pagination fix.
    const filteredOrders = orders.filter(order => {
        const searchLower = searchTerm.toLowerCase();
        const matchesTitle = (order.title || '').toLowerCase().includes(searchLower);
        const matchesDesc = (order.description || '').toLowerCase().includes(searchLower);
        const matchesCity = (order.city || '').toLowerCase().includes(searchLower);
        const matchesDateText = new Date(order.createdAt).toLocaleDateString().includes(searchLower);
        const normalizedCreated = new Date(order.createdAt).toISOString().slice(0, 10);
        const matchesDateFilter = searchDate ? normalizedCreated === searchDate : true;
        return (matchesTitle || matchesDesc || matchesCity || matchesDateText) && matchesDateFilter;
    });

    // Group Archived Orders by City
    const archivedOrdersByCity = useMemo(() => {
        if (orderFilter !== 'archived') return {};
        const grouped = {};
        filteredOrders.forEach(order => {
            const city = order.city || 'Unspecified';
            if (!grouped[city]) grouped[city] = [];
            grouped[city].push(order);
        });
        return grouped;
    }, [filteredOrders, orderFilter]);

    const totalOrders = orderPagination.total || orders.length;
    const totalPages = Math.max(1, Math.ceil(totalOrders / limit));
    const rawOffset = Number.isFinite(orderPagination.offset) ? orderPagination.offset : currentOffset;
    const effectiveOffset = Math.min(rawOffset, Math.max(totalOrders - 1, 0));
    const currentPage = Math.min(Math.floor((effectiveOffset || 0) / limit) + 1, totalPages);
    const pageStart = totalOrders === 0 ? 0 : effectiveOffset + 1;
    const pageEnd = Math.min(totalOrders, effectiveOffset + limit);

    const handlePageChange = (page) => {
        const newPage = Math.min(Math.max(page, 1), totalPages);
        setCurrentOffset((newPage - 1) * limit);
    };

    // Handle Filter Change
    const handleFilterChange = (newFilter) => {
        setOrderFilter(newFilter);
        setCurrentOffset(0);
    };

    // Print Handlers
    const handlePrintOrder = (order) => {
        setOrdersToPrint([order]);
        setTimeout(() => {
            window.print();
            setOrdersToPrint([]);
        }, 100);
    };

    const handlePrintSelected = () => {
        const selectedOrders = orders.filter(o => selectedArchivedOrders.includes(o.id));
        if (selectedOrders.length === 0) {
            alert('Please select orders to print.');
            return;
        }
        setOrdersToPrint(selectedOrders);
        setTimeout(() => {
            window.print();
            setOrdersToPrint([]);
        }, 100);
    };

    return (
        <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
            <header style={{ marginBottom: '2rem' }}>
                <h1>Maker Dashboard</h1>
                <p style={{ color: 'var(--text-muted)' }}>Create and manage your orders.</p>
            </header>

            {/* Create Order Form */}
            <div className="glass-panel" style={{ padding: '2rem', marginBottom: '2rem' }}>
                <h2 style={{ marginBottom: '1.5rem' }}>Create New Order</h2>
                <form onSubmit={handleSubmit}>
                    <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
                        <div style={{ flex: 2 }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem' }}>Customer Name</label>
                            <input
                                type="text"
                                className="input-field"
                                value={title}
                                onChange={(e) => {
                                    setTitle(e.target.value);
                                    fetchTitleSuggestions(e.target.value);
                                }}
                                placeholder="Customer name"
                                list="title-suggestions"
                                required
                            />
                            <datalist id="title-suggestions">
                                {titleSuggestions.map((suggestion, i) => (
                                    <option key={i} value={suggestion} />
                                ))}
                            </datalist>
                        </div>
                        <div style={{ flex: 1 }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem' }}>City</label>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                {cities.map(c => (
                                    <button
                                        key={c}
                                        type="button"
                                        onClick={() => setCity(c)}
                                        className={`btn-secondary ${city === c ? 'active' : ''}`}
                                        style={{
                                            padding: '0.4rem 0.75rem',
                                            borderColor: city === c ? 'var(--primary)' : 'var(--glass-border)',
                                            background: city === c ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                        }}
                                    >
                                        {c}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>

                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>Note (Optional)</label>
                        <textarea
                            className="input-field"
                            value={note}
                            onChange={(e) => setNote(e.target.value)}
                            placeholder="Add a note for the taker..."
                            rows="2"
                        />
                    </div>

                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>Items</label>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            {items.map((item, index) => (
                                <div key={index} style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                                    <span style={{ color: 'var(--text-muted)', minWidth: '20px', textAlign: 'right' }}>{index + 1}.</span>
                                    <input
                                        type="text"
                                        className="input-field"
                                        placeholder="Product Name"
                                        value={item.name}
                                        onChange={(e) => {
                                            handleItemChange(index, 'name', e.target.value);
                                            fetchProductSuggestions(e.target.value);
                                        }}
                                        list="product-suggestions"
                                        required
                                        style={{ flex: 2 }}
                                    />
                                    <datalist id="product-suggestions">
                                        {productSuggestions.map((suggestion, i) => (
                                            <option key={i} value={suggestion} />
                                        ))}
                                    </datalist>
                                    <input
                                        type="number"
                                        className="input-field"
                                        placeholder="Qty"
                                        value={item.quantity}
                                        onChange={(e) => handleItemChange(index, 'quantity', parseInt(e.target.value))}
                                        min="1"
                                        required
                                        style={{ flex: 0.5 }}
                                    />
                                    <input
                                        type="number"
                                        className="input-field"
                                        placeholder="Price (optional)"
                                        value={item.price}
                                        onChange={(e) => handleItemChange(index, 'price', e.target.value === '' ? '' : parseFloat(e.target.value))}
                                        min="0"
                                        step="0.01"
                                        style={{ flex: 0.8 }}
                                    />
                                    {items.length > 1 && (
                                        <button type="button" onClick={() => handleRemoveItem(index)} className="btn-secondary" style={{ color: '#ef4444', borderColor: '#ef4444' }}>
                                            ✕
                                        </button>
                                    )}
                                </div>
                            ))}
                            <button type="button" onClick={handleAddItem} className="btn-secondary" style={{ alignSelf: 'flex-start', marginTop: '0.5rem' }}>
                                + Add Item
                            </button>
                        </div>
                    </div>

                    <div style={{ marginBottom: '1.5rem' }}>
                        <label style={{ display: 'block', marginBottom: '0.5rem' }}>Assign Takers</label>
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                            {users.filter(u => u.role === 'taker').map(taker => (
                                <button
                                    key={taker.id}
                                    type="button"
                                    onClick={() => toggleTaker(taker.id)}
                                    className={`btn-secondary ${selectedTakers.includes(taker.id) ? 'active' : ''}`}
                                    style={{
                                        borderColor: selectedTakers.includes(taker.id) ? 'var(--primary)' : 'var(--glass-border)',
                                        background: selectedTakers.includes(taker.id) ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                    }}
                                >
                                    {taker.name || taker.username} <span style={{ opacity: 0.5, fontSize: '0.8em' }}>(ID: {taker.id})</span>
                                </button>
                            ))}
                        </div>
                    </div>

                    {users.some(u => u.role === 'accounter') && (
                        <div style={{ marginBottom: '1.5rem' }}>
                            <label style={{ display: 'block', marginBottom: '0.5rem' }}>Assign Accounter (optional)</label>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                {users.filter(u => u.role === 'accounter').map(accounter => (
                                    <button
                                        key={accounter.id}
                                        type="button"
                                        onClick={() => setSelectedAccounter(accounter.id === selectedAccounter ? null : accounter.id)}
                                        className={`btn-secondary ${selectedAccounter === accounter.id ? 'active' : ''}`}
                                        style={{
                                            borderColor: selectedAccounter === accounter.id ? 'var(--primary)' : 'var(--glass-border)',
                                            background: selectedAccounter === accounter.id ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                        }}
                                    >
                                        {accounter.username}
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}

                    <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                        <button type="submit" className="btn-primary" style={{ flex: 1 }}>
                            🚀 Send Order
                        </button>
                        <button
                            type="button"
                            className="btn-secondary"
                            style={{ flex: 1, borderColor: 'var(--text-muted)', color: 'var(--text-muted)' }}
                            onClick={(e) => handleSubmit(e, true)}
                        >
                            � Archive Order
                        </button>
                    </div>
                </form>
            </div>

            {showSuccess && (
                <div className="glass-panel fade-in" style={{
                    marginTop: '2rem',
                    padding: '1rem',
                    background: 'rgba(16, 185, 129, 0.2)',
                    borderColor: 'rgba(16, 185, 129, 0.4)',
                    color: '#34d399',
                    textAlign: 'center'
                }}>
                    Order created successfully!
                </div>
            )}
            <div style={{ marginTop: '3rem' }}>
                {/* Orders List */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                    <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                        <button
                            onClick={() => handleFilterChange('active')}
                            style={filterButtonStyle}
                            className={orderFilter === 'active' ? 'btn-primary' : 'btn-secondary'}
                        >
                            Active
                        </button>
                        <button
                            onClick={() => handleFilterChange('completed')}
                            style={filterButtonStyle}
                            className={orderFilter === 'completed' ? 'btn-primary' : 'btn-secondary'}
                        >
                            Completed
                        </button>
                        <button
                            onClick={() => handleFilterChange('entered_erp')}
                            style={filterButtonStyle}
                            className={orderFilter === 'entered_erp' ? 'btn-primary' : 'btn-secondary'}
                        >
                            Entered ERP
                        </button>
                        <button
                            onClick={() => handleFilterChange('archived')}
                            style={filterButtonStyle}
                            className={orderFilter === 'archived' ? 'btn-primary' : 'btn-secondary'}
                        >
                            Archived
                        </button>
                        <button
                            onClick={() => handleFilterChange('all')}
                            style={filterButtonStyle}
                            className={orderFilter === 'all' ? 'btn-primary' : 'btn-secondary'}
                        >
                            All Orders
                        </button>
                    </div>
                    <div style={{ display: 'flex', gap: '1rem' }}>
                        <input
                            type="date"
                            className="input-field"
                            value={searchDate}
                            onChange={(e) => setSearchDate(e.target.value)}
                            style={{ width: '150px' }}
                        />
                        <input
                            type="text"
                            className="input-field"
                            placeholder="Search orders..."
                            value={searchTerm}
                            onChange={(e) => {
                                setSearchTerm(e.target.value);
                                setCurrentOffset(0);
                            }}
                            style={{ width: '250px' }}
                        />
                    </div>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', gap: '1rem', flexWrap: 'wrap' }}>
                    <div style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>
                        Showing {pageStart}-{pageEnd} of {totalOrders} orders
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <button
                            className="btn-secondary"
                            style={{ ...filterButtonStyle, opacity: currentPage === 1 ? 0.6 : 1 }}
                            onClick={() => handlePageChange(currentPage - 1)}
                            disabled={currentPage === 1}
                        >
                            Previous
                        </button>
                        <span style={{ color: 'var(--text-muted)', minWidth: '90px', textAlign: 'center', fontSize: '0.95rem' }}>
                            Page {currentPage} / {totalPages}
                        </span>
                        <button
                            className="btn-secondary"
                            style={{ ...filterButtonStyle, opacity: currentPage === totalPages ? 0.6 : 1 }}
                            onClick={() => handlePageChange(currentPage + 1)}
                            disabled={currentPage === totalPages}
                        >
                            Next
                        </button>
                    </div>
                </div>

                {orderFilter === 'archived' ? (
                    <div style={{ display: 'grid', gap: '2rem' }}>
                        {Object.entries(archivedOrdersByCity).map(([city, cityOrders]) => {
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
                                                className="btn-secondary"
                                                disabled={selectedInCity.length === 0}
                                                onClick={handlePrintSelected}
                                                style={{ borderColor: 'var(--primary)', color: 'var(--primary)' }}
                                            >
                                                🖨️ Print Selected ({selectedInCity.length})
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
                                                padding: '1rem',
                                                background: 'rgba(255,255,255,0.03)',
                                                borderRadius: '8px',
                                                border: selectedArchivedOrders.includes(order.id) ? '1px solid var(--primary)' : '1px solid transparent'
                                            }}>
                                                {editingOrderId === order.id ? (
                                                    <div style={{ marginBottom: '1rem' }}>
                                                        <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
                                                            <input
                                                                type="text"
                                                                className="input-field"
                                                                value={editTitle}
                                                                onChange={(e) => setEditTitle(e.target.value)}
                                                                placeholder="Customer name"
                                                                style={{ flex: 1 }}
                                                            />
                                                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem' }}>
                                                                {cities.map(c => (
                                                                    <button
                                                                        key={c}
                                                                        type="button"
                                                                        onClick={() => setEditCity(c)}
                                                                        className={`btn-secondary ${editCity === c ? 'active' : ''}`}
                                                                        style={{
                                                                            padding: '0.35rem 0.6rem',
                                                                            borderColor: editCity === c ? 'var(--primary)' : 'var(--glass-border)',
                                                                            background: editCity === c ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                                                        }}
                                                                    >
                                                                        {c}
                                                                    </button>
                                                                ))}
                                                            </div>
                                                        </div>

                                                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                                            {editItems.map((item, index) => (
                                                                <div key={index} style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                                                                    <span style={{ color: 'var(--text-muted)', minWidth: '20px', textAlign: 'right' }}>{index + 1}.</span>
                                                                    <input
                                                                        type="text"
                                                                        className="input-field"
                                                                        placeholder="Product Name"
                                                                        value={item.name}
                                                                        onChange={(e) => handleEditItemChange(index, 'name', e.target.value)}
                                                                        style={{ flex: 2 }}
                                                                    />
                                                                    <input
                                                                        type="number"
                                                                        className="input-field"
                                                                        placeholder="Qty"
                                                                        value={item.quantity}
                                                                        onChange={(e) => handleEditItemChange(index, 'quantity', parseInt(e.target.value))}
                                                                        min="1"
                                                                        style={{ flex: 0.5 }}
                                                                    />
                                                                    <input
                                                                        type="number"
                                                                        className="input-field"
                                                                        placeholder="Price (optional)"
                                                                        value={item.price}
                                                                        onChange={(e) => handleEditItemChange(index, 'price', e.target.value === '' ? '' : parseFloat(e.target.value))}
                                                                        min="0"
                                                                        step="0.01"
                                                                        style={{ flex: 0.8 }}
                                                                    />
                                                                    <button type="button" onClick={() => handleEditRemoveItem(index)} className="btn-secondary" style={{ color: '#ef4444', borderColor: '#ef4444' }}>
                                                                        ✕
                                                                    </button>
                                                                </div>
                                                            ))}
                                                            <button type="button" onClick={handleEditAddItem} className="btn-secondary" style={{ alignSelf: 'flex-start', marginTop: '0.5rem' }}>
                                                                + Add Item
                                                            </button>
                                                        </div>

                                                        <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
                                                            <button onClick={() => handleUpdate(order.id)} className="btn-primary" style={{ padding: '0.5rem 1rem' }}>Save Changes</button>
                                                            <button onClick={() => setEditingOrderId(null)} className="btn-secondary" style={{ padding: '0.5rem 1rem' }}>Cancel</button>
                                                        </div>
                                                    </div>
                                                ) : (
                                                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                                                        <input
                                                            type="checkbox"
                                                            checked={selectedArchivedOrders.includes(order.id)}
                                                            onChange={() => handleBulkSelect(order.id)}
                                                            style={{ width: '1.2rem', height: '1.2rem' }}
                                                        />
                                                        <div style={{ flex: 1 }}>
                                                            <div style={{ fontWeight: 'bold' }}>{order.title || 'Untitled'}</div>
                                                            <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                                                {order.Items?.length || 0} items • Created {new Date(order.createdAt).toLocaleDateString()}
                                                            </div>
                                                        </div>
                                                        <button className="btn-secondary" onClick={() => handlePrintOrder(order)} style={{ borderColor: 'var(--primary)', color: 'var(--primary)' }}>🖨️ Print</button>
                                                        <button className="btn-secondary" onClick={() => startEditing(order)}>Edit</button>
                                                        <button className="btn-danger" onClick={() => handleDeleteClick(order)}>Delete</button>
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            );
                        })}
                        {Object.keys(archivedOrdersByCity).length === 0 && (
                            <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '2rem' }}>No archived orders found.</p>
                        )}
                    </div>
                ) : (
                    <div style={{ display: 'grid', gap: '1.5rem' }}>
                        {filteredOrders.length === 0 ? (
                            <div className="glass-panel" style={{ padding: '3rem', textAlign: 'center', color: 'var(--text-muted)' }}>
                                <p>No orders found matching your criteria.</p>
                            </div>
                        ) : (
                            filteredOrders.map(order => (
                                <div key={order.id} className="glass-panel" style={{ padding: '1.5rem' }}>
                                    <div className="order-header" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem', gap: '1rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flex: 1 }}>
                                            <span style={{ fontFamily: 'monospace', background: 'rgba(255,255,255,0.1)', padding: '0.2rem 0.5rem', borderRadius: '4px' }}>
                                                #{String(order.id).padStart(6, '0')}
                                            </span>
                                            {editingOrderId === order.id ? (
                                                <div style={{ display: 'flex', gap: '0.5rem' }}>
                                                    <input
                                                        type="text"
                                                        className="input-field"
                                                        value={editTitle}
                                                        onChange={(e) => setEditTitle(e.target.value)}
                                                        placeholder="Customer name"
                                                        style={{ padding: '0.2rem 0.5rem', fontSize: '1rem' }}
                                                    />
                                                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.4rem' }}>
                                                        {cities.map(c => (
                                                            <button
                                                                key={c}
                                                                type="button"
                                                                onClick={() => setEditCity(c)}
                                                                className={`btn-secondary ${editCity === c ? 'active' : ''}`}
                                                                style={{
                                                                    padding: '0.35rem 0.6rem',
                                                                    borderColor: editCity === c ? 'var(--primary)' : 'var(--glass-border)',
                                                                    background: editCity === c ? 'rgba(251, 191, 36, 0.1)' : 'transparent'
                                                                }}
                                                            >
                                                                {c}
                                                            </button>
                                                        ))}
                                                    </div>
                                                </div>
                                            ) : (
                                                <div style={{ display: 'flex', flexDirection: 'column' }}>
                                                    <span style={{ fontWeight: 'bold', fontSize: '1.1rem' }}>{order.title || 'Untitled Order'}</span>
                                                    {order.city && (
                                                        <span style={{ fontSize: '0.8rem', color: 'var(--primary)', display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                                                            🏙️ {order.city}
                                                        </span>
                                                    )}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
                                        {editingOrderId !== order.id ? (
                                            <span style={{
                                                color: order.status === 'completed' ? '#34d399' :
                                                    order.status === 'in-progress' ? '#fbbf24' :
                                                        order.status === 'entered_erp' ? '#8b5cf6' : '#94a3b8',
                                                textTransform: 'capitalize'
                                            }}>
                                                {order.status === 'entered_erp' ? 'Entered into ERP' : order.status}
                                            </span>
                                        ) : (
                                            <select
                                                value={editStatus}
                                                onChange={(e) => setEditStatus(e.target.value)}
                                                style={{
                                                    padding: '0.3rem 0.5rem',
                                                    borderRadius: '4px',
                                                    border: '1px solid var(--glass-border)',
                                                    background: 'var(--glass-bg)',
                                                    color: 'var(--text-main)',
                                                    fontSize: '0.9rem'
                                                }}
                                            >
                                                <option value="pending">Pending</option>
                                                <option value="in-progress">In Progress</option>
                                                <option value="completed">Completed</option>
                                                <option value="archived">Archived</option>
                                            </select>
                                        )}
                                        <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                            {new Date(order.createdAt).toLocaleDateString()}
                                        </span>
                                        {editingOrderId !== order.id && (
                                            <>
                                                <button className="btn-secondary" onClick={() => handlePrintOrder(order)} style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem', borderColor: 'var(--primary)', color: 'var(--primary)' }}>
                                                    🖨️ Print
                                                </button>
                                                <button onClick={() => startEditing(order)} className="btn-secondary" style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem' }}>
                                                    Edit
                                                </button>
                                                {order.status === 'completed' && (
                                                    <button
                                                        onClick={() => handleErpClick(order)}
                                                        className="btn-primary"
                                                        style={{ padding: '0.3rem 0.8rem', fontSize: '0.8rem', background: '#8b5cf6', borderColor: '#8b5cf6' }}
                                                        title="Mark as Entered to ERP"
                                                    >
                                                        🧾 To ERP
                                                    </button>
                                                )}
                                                <button
                                                    onClick={() => {
                                                        if (window.confirm('Are you sure you want to delete this order? This action cannot be undone.')) {
                                                            deleteOrder(order.id);
                                                        }
                                                    }}
                                                    className="btn-secondary"
                                                    style={{ padding: '0.2rem 0.5rem', fontSize: '0.8rem', color: '#ef4444', borderColor: '#ef4444' }}
                                                >
                                                    Delete
                                                </button>
                                            </>
                                        )}
                                    </div>

                                    {editingOrderId === order.id ? (
                                        <div style={{ marginBottom: '1rem' }}>
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginTop: '1rem' }}>
                                                {editItems.map((item, index) => (
                                                    <div key={index} style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                                                        <input
                                                            type="text"
                                                            className="input-field"
                                                            placeholder="Product Name"
                                                            value={item.name}
                                                            onChange={(e) => {
                                                                handleEditItemChange(index, 'name', e.target.value);
                                                                fetchProductSuggestions(e.target.value);
                                                            }}
                                                            list="product-suggestions"
                                                            style={{ flex: 2 }}
                                                        />
                                                        <input
                                                            type="number"
                                                            className="input-field"
                                                            placeholder="Qty"
                                                            value={item.quantity}
                                                            onChange={(e) => handleEditItemChange(index, 'quantity', parseInt(e.target.value))}
                                                            min="1"
                                                            style={{ flex: 0.5 }}
                                                        />
                                                        <input
                                                            type="number"
                                                            className="input-field"
                                                            placeholder="Price (optional)"
                                                            value={item.price}
                                                            onChange={(e) => handleEditItemChange(index, 'price', e.target.value === '' ? '' : parseFloat(e.target.value))}
                                                            min="0"
                                                            step="0.01"
                                                            style={{ flex: 0.8 }}
                                                        />
                                                        <button type="button" onClick={() => handleEditRemoveItem(index)} className="btn-secondary" style={{ color: '#ef4444', borderColor: '#ef4444' }}>
                                                            ✕
                                                        </button>
                                                    </div>
                                                ))}
                                                <button type="button" onClick={handleEditAddItem} className="btn-secondary" style={{ alignSelf: 'flex-start', marginTop: '0.5rem' }}>
                                                    + Add Item
                                                </button>
                                            </div>

                                            <div style={{ marginTop: '1.5rem' }}>
                                                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.9rem' }}>Assigned Takers</label>
                                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                                    {users.filter(u => u.role === 'taker').map(taker => (
                                                        <button
                                                            key={taker.id}
                                                            type="button"
                                                            onClick={() => toggleEditTaker(taker.id)}
                                                            className={`btn-secondary ${editSelectedTakers.includes(taker.id) ? 'active' : ''}`}
                                                            style={{
                                                                borderColor: editSelectedTakers.includes(taker.id) ? 'var(--primary)' : 'var(--glass-border)',
                                                                background: editSelectedTakers.includes(taker.id) ? 'rgba(251, 191, 36, 0.1)' : 'transparent',
                                                                fontSize: '0.8rem',
                                                                padding: '0.3rem 0.6rem'
                                                            }}
                                                        >
                                                            {taker.name || taker.username}
                                                        </button>
                                                    ))}
                                                </div>
                                            </div>

                                            {users.some(u => u.role === 'accounter') && (
                                                <div style={{ marginTop: '1rem' }}>
                                                    <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.9rem' }}>Accounter</label>
                                                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                                        {users.filter(u => u.role === 'accounter').map(accounter => (
                                                            <button
                                                                key={accounter.id}
                                                                type="button"
                                                                onClick={() => setEditAccounter(accounter.id === editAccounter ? null : accounter.id)}
                                                                className={`btn-secondary ${editAccounter === accounter.id ? 'active' : ''}`}
                                                                style={{
                                                                    borderColor: editAccounter === accounter.id ? 'var(--primary)' : 'var(--glass-border)',
                                                                    background: editAccounter === accounter.id ? 'rgba(251, 191, 36, 0.1)' : 'transparent',
                                                                    fontSize: '0.8rem',
                                                                    padding: '0.3rem 0.6rem'
                                                                }}
                                                            >
                                                                {accounter.username}
                                                            </button>
                                                        ))}
                                                    </div>
                                                </div>
                                            )}

                                            <div style={{ display: 'flex', gap: '0.5rem', marginTop: '1rem' }}>
                                                <button onClick={() => handleUpdate(order.id)} className="btn-primary" style={{ padding: '0.5rem 1rem' }}>Save Changes</button>
                                                <button onClick={() => setEditingOrderId(null)} className="btn-secondary" style={{ padding: '0.5rem 1rem' }}>Cancel</button>
                                            </div>
                                        </div>
                                    ) : (
                                        <>
                                            {order.description && !order.description.startsWith('Order with') && (
                                                <p style={{ fontSize: '1rem', marginBottom: '1rem', fontStyle: 'italic', color: 'var(--text-muted)' }}>{order.description}</p>
                                            )}

                                            {order.Accounter && (
                                                <div style={{ marginBottom: '0.75rem', color: 'var(--text-muted)' }}>
                                                    🧾 Accounter: <span style={{ color: 'var(--text-main)', fontWeight: 600 }}>{order.Accounter.username}</span>
                                                </div>
                                            )}

                                            {order.Items && order.Items.length > 0 && (
                                                <table className="order-items-table" style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '1rem' }}>
                                                    <thead>
                                                        <tr style={{ borderBottom: '1px solid var(--glass-border)', textAlign: 'left' }}>
                                                            <th style={{ padding: '0.5rem', color: 'var(--text-muted)', width: '40px' }}>#</th>
                                                            <th style={{ padding: '0.5rem', color: 'var(--text-muted)' }}>Product</th>
                                                            <th style={{ padding: '0.5rem', color: 'var(--text-muted)', textAlign: 'right' }}>Qty</th>
                                                            <th style={{ padding: '0.5rem', color: 'var(--text-muted)', textAlign: 'right' }}>Price</th>
                                                            <th style={{ padding: '0.5rem', color: 'var(--text-muted)', textAlign: 'center' }}>Status</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        {order.Items.map((item, index) => {
                                                            const getRowStyle = () => {
                                                                const baseStyle = {
                                                                    borderBottom: '1px solid rgba(255,255,255,0.05)',
                                                                    transition: 'background-color 0.3s ease'
                                                                };

                                                                if (item.status === 'collected') {
                                                                    return {
                                                                        ...baseStyle,
                                                                        backgroundColor: 'rgba(52, 211, 153, 0.15)',
                                                                        borderLeft: '3px solid #34d399'
                                                                    };
                                                                } else if (item.status === 'unavailable') {
                                                                    return {
                                                                        ...baseStyle,
                                                                        backgroundColor: 'rgba(239, 68, 68, 0.15)',
                                                                        borderLeft: '3px solid #ef4444'
                                                                    };
                                                                }
                                                                return baseStyle;
                                                            };

                                                            return (
                                                                <tr key={item.id} style={getRowStyle()}>
                                                                    <td style={{ padding: '0.5rem', color: 'var(--text-muted)' }}>{index + 1}</td>
                                                                    <td className="item-name" style={{
                                                                        padding: '0.5rem',
                                                                        textDecoration: item.status === 'unavailable' ? 'line-through' : 'none',
                                                                        opacity: item.status === 'unavailable' ? 0.6 : 1
                                                                    }}>{item.name}</td>
                                                                    <td className="item-qty" style={{
                                                                        padding: '0.5rem',
                                                                        textAlign: 'right',
                                                                        opacity: item.status === 'unavailable' ? 0.6 : 1,
                                                                        fontSize: '1.1rem',
                                                                        color: '#fff',
                                                                        fontWeight: 700
                                                                    }}>{item.quantity}</td>
                                                                    <td style={{ padding: '0.5rem', textAlign: 'right', opacity: item.status === 'unavailable' ? 0.6 : 1, fontSize: '1.1rem', color: '#fff', fontWeight: 700 }}>
                                                                        {item.price !== null && item.price !== undefined && item.price !== '' ? `${item.price} ₪` : '-'}
                                                                    </td>
                                                                    <td style={{ padding: '0.5rem', textAlign: 'center' }}>
                                                                        {item.status === 'collected' && (
                                                                            <span style={{ color: '#34d399', fontSize: '1.2rem' }} title="Collected">✓</span>
                                                                        )}
                                                                        {item.status === 'unavailable' && (
                                                                            <span style={{ color: '#ef4444', fontSize: '1.2rem' }} title="Unavailable">✕</span>
                                                                        )}
                                                                        {!item.status && (
                                                                            <span style={{ color: 'var(--text-muted)', fontSize: '0.8rem' }}>-</span>
                                                                        )}
                                                                    </td>
                                                                </tr>
                                                            );
                                                        })}
                                                    </tbody>
                                                </table>
                                            )}
                                        </>
                                    )}

                                    <div style={{ borderTop: '1px solid var(--glass-border)', paddingTop: '1rem', fontSize: '0.9rem', color: 'var(--text-muted)' }}>
                                        Assigned to: <span style={{ color: 'var(--text-main)' }}>
                                            {order.AssignedTakers?.map(t => t.username).join(', ') || 'None'}
                                        </span>
                                    </div>

                                    {order.History && order.History.length > 0 && (
                                        <div style={{ marginTop: '1rem' }}>
                                            <button
                                                onClick={() => setExpandedHistoryId(expandedHistoryId === order.id ? null : order.id)}
                                                style={{ background: 'none', border: 'none', color: 'var(--primary)', cursor: 'pointer', padding: 0, fontSize: '0.9rem' }}
                                            >
                                                {expandedHistoryId === order.id ? 'Hide History' : `View Edit History(${order.History.length})`}
                                            </button>

                                            {expandedHistoryId === order.id && (
                                                <div style={{ marginTop: '0.5rem', background: 'rgba(0,0,0,0.2)', borderRadius: '8px', padding: '1rem' }}>
                                                    {[...order.History].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).map(log => {
                                                        let logColor = 'var(--text-main)';
                                                        let icon = '📝';

                                                        if (log.newDescription.startsWith('Added:')) {
                                                            logColor = '#34d399'; // Green
                                                            icon = '➕';
                                                        } else if (log.newDescription.startsWith('Removed:')) {
                                                            logColor = '#ef4444'; // Red
                                                            icon = '❌';
                                                        } else if (log.newDescription.startsWith('Updated')) {
                                                            logColor = '#fbbf24'; // Yellow
                                                            icon = '🔄';
                                                        } else if (log.newDescription.startsWith('Title:')) {
                                                            logColor = '#60a5fa'; // Blue
                                                            icon = '🏷️';
                                                        } else if (log.newDescription.startsWith('City:')) {
                                                            logColor = '#a78bfa'; // Purple
                                                            icon = '🏙️';
                                                        }

                                                        return (
                                                            <div key={log.id} style={{ marginBottom: '0.8rem', borderBottom: '1px solid rgba(255,255,255,0.05)', paddingBottom: '0.5rem' }}>
                                                                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.2rem' }}>
                                                                    <span>{new Date(log.createdAt).toLocaleString()}</span>
                                                                    <span style={{ fontStyle: 'italic' }}>by {log.Editor ? log.Editor.username : 'Unknown'}</span>
                                                                </div>
                                                                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: logColor, fontSize: '0.9rem' }}>
                                                                    <span>{icon}</span>
                                                                    <span>{log.newDescription}</span>
                                                                </div>
                                                            </div>
                                                        );
                                                    })}
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            ))
                        )}
                    </div>
                )}

                {/* Bulk Send Modal */}
                {showBulkSendModal && (
                    <div style={{
                        position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
                        background: 'rgba(0,0,0,0.8)', display: 'flex', justifyContent: 'center', alignItems: 'center',
                        zIndex: 1000
                    }}>
                        <div className="glass-panel" style={{ padding: '2rem', width: '90%', maxWidth: '500px' }}>
                            <h2 style={{ marginBottom: '1rem' }}>Send Orders to Takers</h2>
                            <p style={{ marginBottom: '1.5rem', color: 'var(--text-muted)' }}>
                                Assigning {selectedArchivedOrders.filter(id => orders.find(o => o.id === id)?.city === bulkSendCity).length} orders in {bulkSendCity}.
                            </p>

                            <div style={{ marginBottom: '1.5rem' }}>
                                <label style={{ display: 'block', marginBottom: '0.5rem' }}>Select Takers</label>
                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                    {users.filter(u => u.role === 'taker').map(taker => (
                                        <button
                                            key={taker.id}
                                            type="button"
                                            className={`btn-secondary ${bulkSendTakers.includes(taker.id) ? 'active' : ''}`}
                                            onClick={() => toggleBulkTaker(taker.id)}
                                            style={{ borderColor: bulkSendTakers.includes(taker.id) ? 'var(--primary)' : undefined }}
                                        >
                                            {taker.username}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <div style={{ marginBottom: '1.5rem' }}>
                                <label style={{ display: 'block', marginBottom: '0.5rem' }}>Select Accounter</label>
                                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                                    {users.filter(u => u.role === 'accounter').map(accounter => (
                                        <button
                                            key={accounter.id}
                                            type="button"
                                            className={`btn-secondary ${bulkSendAccounter === accounter.id ? 'active' : ''}`}
                                            onClick={() => toggleBulkAccounter(accounter.id)}
                                            style={{ borderColor: bulkSendAccounter === accounter.id ? 'var(--primary)' : undefined }}
                                        >
                                            {accounter.username}
                                        </button>
                                    ))}
                                    {users.filter(u => u.role === 'accounter').length === 0 && (
                                        <p style={{ color: 'var(--text-muted)' }}>No accounters available.</p>
                                    )}
                                </div>
                            </div>

                            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem' }}>
                                <button className="btn-secondary" onClick={resetBulkSendState}>Cancel</button>
                                <button className="btn-primary" onClick={confirmBulkSend}>Confirm & Send</button>
                            </div>
                        </div>
                    </div>
                )}
                {/* ERP Confirmation Modal */}
                <ConfirmModal
                    isOpen={showErpModal}
                    onClose={() => setShowErpModal(false)}
                    onConfirm={confirmErp}
                    title="Mark as Entered to ERP"
                    message={`Are you sure you want to mark order #${orderToErp?.id} as Entered to ERP? This action cannot be undone easily.`}
                />

                {/* Delete Confirmation Modal */}
                <ConfirmModal
                    isOpen={showDeleteModal}
                    onClose={() => setShowDeleteModal(false)}
                    onConfirm={confirmDelete}
                    title="Delete Order"
                    message={`Are you sure you want to delete order #${orderToDelete?.id}? This action cannot be undone.`}
                />

                {/* Printable Orders */}
                <PrintableOrder orders={ordersToPrint} />
            </div>
        </div>
    );
};

export default MakerDashboard;
