require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const net = require('net');
const { DataTypes } = require('sequelize');
const { sequelize, OrderAssignments, Order, User, OrderItem } = require('./db');
const { seedAdmin } = require('./utils/seedAdmin');

const app = express();
const PREFERRED_PORT = Number(process.env.PORT) || 6001;

const isPortAvailable = (port) => new Promise((resolve, reject) => {
    const tester = net
        .createServer()
        .once('error', (err) => {
            if (err.code === 'EADDRINUSE' || err.code === 'EACCES') {
                resolve(false);
            } else {
                reject(err);
            }
        })
        .once('listening', () => {
            tester.close(() => resolve(true));
        })
        .listen(port, '0.0.0.0');
});

const findAvailablePort = async (preferredPort, attempts = 10) => {
    const available = await isPortAvailable(preferredPort);
    if (available) {
        return preferredPort;
    }

    throw new Error(`Port ${preferredPort} is not available. Please stop the process using it or set PORT env.`);
};

// Middleware: allow all origins (mobile/web clients on LAN)
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(express.json());

// Certificate Authentication Middleware - DISABLED
// const { validateClientCertificate } = require('./middleware/certificateAuth');
// app.use(validateClientCertificate);

// Sync Database and seed admin
const syncDatabase = async () => {
    try {
        const queryInterface = sequelize.getQueryInterface();
        const orderTable = await queryInterface.describeTable('Orders');

        if (!orderTable.accounterId) {
            await queryInterface.addColumn('Orders', 'accounterId', {
                type: DataTypes.INTEGER,
                allowNull: true,
                references: {
                    model: 'Users',
                    key: 'id'
                },
                onUpdate: 'CASCADE',
                onDelete: 'SET NULL'
            });
            console.log('Added accounterId column to Orders table');
        }

        await sequelize.sync();

        // Alter Order table to allow null description
        try {
            await Order.sync({ alter: true });
            console.log('Order table altered');
        } catch (err) {
            console.error('Error altering Order table:', err);
        }

        // Alter User table to add email column
        try {
            await User.sync({ alter: true });
            console.log('User table altered - email column added');
        } catch (err) {
            console.error('Error altering User table:', err);
        }

        // Alter OrderItem table to add status column
        try {
            await OrderItem.sync({ alter: true });
            console.log('OrderItem table altered - status column added');
        } catch (err) {
            console.error('Error altering OrderItem table:', err);
        }

        console.log('Database synced');
        await seedAdmin();
    } catch (error) {
        console.error('Failed to sync database:', error);
    }
};

syncDatabase();

// Routes
const authRoutes = require('./routes/auth');
const orderRoutes = require('./routes/orders');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');

app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/items', require('./routes/items'));

// Export for routes to use
module.exports = { app, sequelize };

const startServer = async () => {
    const portToUse = await findAvailablePort(PREFERRED_PORT);

    http.createServer(app).listen(portToUse, '0.0.0.0', () => {
        console.log(`HTTP server running on http://localhost:${portToUse}`);
        console.log(`Also accessible on the LAN at http://10.10.10.110:${portToUse}`);
    });
};

// Start HTTP Server
if (require.main === module) {
    startServer().catch((error) => {
        console.error('Failed to start server:', error);
        process.exit(1);
    });
}
