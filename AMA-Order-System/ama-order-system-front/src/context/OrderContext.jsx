import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './AuthContext';
import { API_BASE_URL } from '../utils/api';

const OrderContext = createContext();

export const useOrder = () => useContext(OrderContext);

export const OrderProvider = ({ children }) => {
  const { token, user } = useAuth();
  const [orders, setOrders] = useState([]);
  const [orderPagination, setOrderPagination] = useState({ total: 0, limit: 20, offset: 0 });
  const [users, setUsers] = useState([]); // Takers list for Makers

  const fetchOrders = useCallback(async (options = {}) => {
    if (!token) return;
    try {
      const limit = Math.min(Number.isFinite(options.limit) ? options.limit : 20, 20);
      const offset = Math.max(Number.isFinite(options.offset) ? options.offset : 0, 0);
      const search = (options.search || '').trim();
      const params = new URLSearchParams({ limit, offset });

      if (options.status) {
        params.append('status', options.status);
      }

      if (search) {
        params.append('search', search);
      }

      const response = await fetch(`${API_BASE_URL}/api/orders?${params.toString()}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (response.ok) {
        const data = await response.json();
        const pagination = data.pagination || { total: data.orders?.length || data.length || 0, limit, offset };

        if (Array.isArray(data)) {
          setOrders(data);
        } else {
          setOrders(data.orders || []);
        }

        setOrderPagination({ ...pagination, limit, offset });
      }
    } catch (error) {
      console.error('Failed to fetch orders', error);
    }
  }, [token]);

  const fetchTakers = useCallback(async () => {
    const isMakerOrAdmin = user?.role === 'maker' || user?.role === 'admin';

    if (!token || !isMakerOrAdmin) return;
    try {
      const [takersRes, accountersRes] = await Promise.all([
        fetch(`${API_BASE_URL}/api/auth/takers`, { headers: { 'Authorization': `Bearer ${token}` } }),
        fetch(`${API_BASE_URL}/api/auth/accounters`, { headers: { 'Authorization': `Bearer ${token}` } })
      ]);

      const combined = [];
      if (takersRes.ok) {
        combined.push(...await takersRes.json());
      }
      if (accountersRes.ok) {
        combined.push(...await accountersRes.json());
      }

      setUsers(combined);
    } catch (error) {
      console.error('Failed to fetch takers', error);
    }
  }, [token, user]);

  useEffect(() => {
    if (token) {
      fetchOrders();
      fetchTakers();
    } else {
      setOrders([]);
      setUsers([]);
    }
  }, [token, fetchOrders, fetchTakers]);

  const createOrder = async (orderData, assignedTakerIds) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ ...orderData, assignedTakerIds }),
      });

      if (response.ok) {
        await fetchOrders(); // Refresh list
        return true;
      }

      const data = await response.json().catch(() => ({}));
      const message = data.error || 'Failed to create order';
      alert(message);
      return false;
    } catch (error) {
      console.error('Failed to create order', error);
    }
    return false;
  };

  const getOrdersForUser = (userId) => {
    // In the new backend model, the API returns only relevant orders.
    // So we just return all 'orders' which are already filtered by the backend.
    return orders;
  };

  const updateOrderStatus = async (orderId, status) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/orders/${orderId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ status }),
      });

      if (response.ok) {
        const updatedOrder = await response.json();
        setOrders(prev => prev.map(order =>
          order.id === orderId ? updatedOrder : order
        ));
        return true;
      }
    } catch (error) {
      console.error('Failed to update status', error);
    }
    return false;
  };

  const updateOrderDetails = async (orderId, details) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/orders/${orderId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(details),
      });

      if (response.ok) {
        const updatedOrder = await response.json();
        setOrders(prev => prev.map(order =>
          order.id === orderId ? updatedOrder : order
        ));
        return true;
      }

      const data = await response.json().catch(() => ({}));
      const message = data.error || 'Failed to update order';
      alert(message);
      return false;
    } catch (error) {
      console.error('Failed to update details', error);
    }
    return false;
  };

  const deleteOrder = async (orderId) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/orders/${orderId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`
        },
      });

      if (response.ok) {
        setOrders(prev => prev.filter(order => order.id !== orderId));
        return true;
      }
    } catch (error) {
      console.error('Failed to delete order', error);
    }
    return false;
  };

  return (
    <OrderContext.Provider value={{ orders, orderPagination, users, createOrder, getOrdersForUser, updateOrderStatus, updateOrderDetails, deleteOrder, fetchOrders }}>
      {children}
    </OrderContext.Provider>
  );
};
