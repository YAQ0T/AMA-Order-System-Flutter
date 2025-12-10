import React from 'react';

const PrintableOrder = ({ orders, onClose }) => {
    if (!orders || orders.length === 0) return null;

    const printStyles = `
        @media print {
            body * { visibility: hidden; }
            #printable-orders, #printable-orders * { visibility: visible; }
            #printable-orders { position: absolute; left: 0; top: 0; width: 100%; display: block; }
        }
    `;

    const formatDate = (dateString) => {
        return new Date(dateString).toLocaleDateString('en-GB', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    const calculateTotal = (items) => {
        return items.reduce((sum, item) => {
            const price = parseFloat(item.price) || 0;
            const quantity = parseInt(item.quantity) || 0;
            return sum + (price * quantity);
        }, 0);
    };

    const getStatusLabel = (status) => {
        const statusMap = {
            'pending': 'قيد الانتظار - Pending',
            'in_progress': 'قيد التنفيذ - In Progress',
            'completed': 'مكتمل - Completed',
            'archived': 'مؤرشف - Archived',
            'entered_erp': 'تم الإدخال في ERP - Entered to ERP'
        };
        return statusMap[status] || status;
    };

    return (
        <div id="printable-orders" style={{ display: orders.length > 0 ? 'block' : 'none' }}>
            <style>{printStyles}</style>
            {orders.map((order, orderIndex) => (
                <div key={order.id} className="printable-order-page" style={{ pageBreakAfter: orderIndex < orders.length - 1 ? 'always' : 'auto' }}>
                    <div style={{
                        fontFamily: 'Arial, sans-serif',
                        padding: '20px',
                        maxWidth: '800px',
                        margin: '0 auto'
                    }}>
                        {/* Header */}
                        <div style={{
                            borderBottom: '3px solid #333',
                            paddingBottom: '15px',
                            marginBottom: '20px',
                            textAlign: 'center'
                        }}>
                            <h1 style={{ margin: '0 0 10px 0', fontSize: '28px', color: '#333' }}>
                                AMA Order System
                            </h1>
                            <h2 style={{ margin: '0', fontSize: '20px', color: '#666' }}>
                                نظام طلبات AMA
                            </h2>
                        </div>

                        {/* Order Info */}
                        <div style={{
                            display: 'flex',
                            flexWrap: 'wrap',
                            gap: '8px 16px',
                            marginBottom: '14px',
                            padding: '10px 12px',
                            backgroundColor: '#f5f5f5',
                            borderRadius: '8px',
                            alignItems: 'center'
                        }}>
                            <div><strong style={{ fontSize: '13px', color: '#666' }}>Order #:</strong> <span style={{ fontSize: '15px' }}>{order.id}</span></div>
                            <div><strong style={{ fontSize: '13px', color: '#666' }}>Date:</strong> <span style={{ fontSize: '14px' }}>{formatDate(order.createdAt)}</span></div>
                            <div><strong style={{ fontSize: '13px', color: '#666' }}>City:</strong> <span style={{ fontSize: '14px' }}>{order.city || 'N/A'}</span></div>
                            <div><strong style={{ fontSize: '13px', color: '#666' }}>Status:</strong> <span style={{ fontSize: '14px' }}>{getStatusLabel(order.status)}</span></div>
                            <div style={{ flexBasis: '100%' }}><strong style={{ fontSize: '13px', color: '#666' }}>Customer:</strong> <span style={{ fontSize: '15px', fontWeight: 'bold' }}>{order.title || 'N/A'}</span></div>
                            {order.description && (
                                <div style={{ flexBasis: '100%' }}>
                                    <strong style={{ fontSize: '13px', color: '#666' }}>Notes:</strong> <span style={{ fontSize: '13px', lineHeight: 1.4 }}>{order.description}</span>
                                </div>
                            )}
                        </div>

                        {/* Items Table */}
                        <div style={{ marginBottom: '25px' }}>
                            <h3 style={{ marginBottom: '15px', fontSize: '18px', borderBottom: '2px solid #333', paddingBottom: '8px' }}>
                                المنتجات - Items
                            </h3>
                            <table style={{
                                width: '100%',
                                borderCollapse: 'collapse',
                                fontSize: '14px',
                                background: '#fff',
                                color: '#000',
                                border: '1px solid #ddd'
                            }}>
                                <thead>
                                    <tr style={{ backgroundColor: '#fff', color: '#000', borderBottom: '2px solid #333' }}>
                                        <th style={{ padding: '12px', textAlign: 'left', border: '1px solid #ddd' }}>#</th>
                                        <th style={{ padding: '12px', textAlign: 'left', border: '1px solid #ddd' }}>اسم المنتج - Product Name</th>
                                        <th style={{ padding: '12px', textAlign: 'center', border: '1px solid #ddd' }}>الكمية - Qty</th>
                                        <th style={{ padding: '12px', textAlign: 'right', border: '1px solid #ddd' }}>السعر - Price</th>
                                        <th style={{ padding: '12px', textAlign: 'right', border: '1px solid #ddd' }}>المجموع - Total</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {order.Items && order.Items.map((item, index) => {
                                        const price = parseFloat(item.price) || 0;
                                        const quantity = parseInt(item.quantity) || 0;
                                        const total = price * quantity;
                                        return (
                                            <tr key={index} style={{ backgroundColor: '#fff' }}>
                                                <td style={{ padding: '10px', border: '1px solid #ddd' }}>{index + 1}</td>
                                                <td style={{ padding: '10px', border: '1px solid #ddd' }}>{item.name}</td>
                                                <td style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'center' }}>{quantity}</td>
                                                <td style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'right' }}>
                                                    {price > 0 ? `${price.toFixed(2)} ₪` : '-'}
                                                </td>
                                                <td style={{ padding: '10px', border: '1px solid #ddd', textAlign: 'right', fontWeight: 'bold' }}>
                                                    {total > 0 ? `${total.toFixed(2)} ₪` : '-'}
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                                {order.Items && order.Items.some(item => parseFloat(item.price) > 0) && (
                                    <tfoot>
                                        <tr style={{ backgroundColor: '#fff', color: '#000', fontWeight: 'bold' }}>
                                            <td colSpan="4" style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'right' }}>
                                                المجموع الكلي - Grand Total:
                                            </td>
                                            <td style={{ padding: '12px', border: '1px solid #ddd', textAlign: 'right', fontSize: '16px' }}>
                                                {calculateTotal(order.Items).toFixed(2)} ₪
                                            </td>
                                        </tr>
                                    </tfoot>
                                )}
                            </table>
                        </div>

                        {/* Assigned Staff */}
                        <div style={{
                            display: 'grid',
                            gridTemplateColumns: '1fr 1fr',
                            gap: '15px',
                            padding: '15px',
                            backgroundColor: '#f5f5f5',
                            borderRadius: '8px'
                        }}>
                            {order.AssignedTakers && order.AssignedTakers.length > 0 && (
                                <div>
                                    <strong style={{ fontSize: '14px', color: '#666' }}>المكلفون - Assigned Takers:</strong>
                                    <div style={{ fontSize: '14px', marginTop: '5px' }}>
                                        {order.AssignedTakers.map(t => t.name || t.username).join(', ')}
                                    </div>
                                </div>
                            )}
                            {order.Accounter && (
                                <div>
                                    <strong style={{ fontSize: '14px', color: '#666' }}>المحاسب - Accounter:</strong>
                                    <div style={{ fontSize: '14px', marginTop: '5px' }}>
                                        {order.Accounter.name || order.Accounter.username}
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Footer */}
                        <div style={{
                            marginTop: '40px',
                            paddingTop: '15px',
                            borderTop: '2px solid #ddd',
                            textAlign: 'center',
                            fontSize: '12px',
                            color: '#999'
                        }}>
                            <p style={{ margin: '5px 0' }}>Printed on: {new Date().toLocaleString('en-GB')}</p>
                            <p style={{ margin: '5px 0' }}>AMA Order System - نظام طلبات AMA</p>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
};

export default PrintableOrder;
