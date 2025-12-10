const { Sequelize } = require('sequelize');
const path = require('path');

const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASSWORD,
    {
        host: process.env.DB_HOST,
        dialect: 'postgres',
        logging: false,
        pool: {
            max: 20,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

const User = require('./models/User')(sequelize);
const Order = require('./models/Order')(sequelize);
const OrderItem = require('./models/OrderItem')(sequelize);
const OrderLog = require('./models/OrderLog')(sequelize);
const Notification = require('./models/Notification')(sequelize);
const PushSubscription = require('./models/PushSubscription')(sequelize);
const OrderAssignments = require('./models/OrderAssignments')(sequelize);
const ActivityLog = require('./models/ActivityLog')(sequelize);

// Associations
// User <-> Order (Maker)
User.hasMany(Order, { as: 'CreatedOrders', foreignKey: 'makerId' });
Order.belongsTo(User, { as: 'Maker', foreignKey: 'makerId' });

// User <-> Order (Taker Assignment - Many-to-Many)
User.belongsToMany(Order, { through: OrderAssignments, as: 'AssignedOrders', foreignKey: 'userId' });
Order.belongsToMany(User, { through: OrderAssignments, as: 'AssignedTakers', foreignKey: 'orderId' });

// User <-> Order (Accounter)
User.hasMany(Order, { as: 'AssignedAccountingOrders', foreignKey: 'accounterId' });
Order.belongsTo(User, { as: 'Accounter', foreignKey: 'accounterId' });

// Order <-> OrderItem
Order.hasMany(OrderItem, { as: 'Items', foreignKey: 'orderId' });
OrderItem.belongsTo(Order, { foreignKey: 'orderId' });

// Order <-> OrderLog
Order.hasMany(OrderLog, { as: 'History', foreignKey: 'orderId' });
OrderLog.belongsTo(Order, { foreignKey: 'orderId' });

// User <-> OrderLog (Editor)
User.hasMany(OrderLog, { foreignKey: 'changedBy' });
OrderLog.belongsTo(User, { as: 'Editor', foreignKey: 'changedBy' });

// User <-> Notification
User.hasMany(Notification, { foreignKey: 'userId' });
Notification.belongsTo(User, { foreignKey: 'userId' });

// User <-> PushSubscription
User.hasMany(PushSubscription, { foreignKey: 'userId' });
PushSubscription.belongsTo(User, { foreignKey: 'userId' });

// User <-> ActivityLog
User.hasMany(ActivityLog, { foreignKey: 'userId' });
ActivityLog.belongsTo(User, { as: 'User', foreignKey: 'userId' });

// User self-referential for approval
User.belongsTo(User, { as: 'Approver', foreignKey: 'approvedBy' });
User.hasMany(User, { as: 'ApprovedUsers', foreignKey: 'approvedBy' });

module.exports = { sequelize, User, Order, OrderItem, OrderLog, Notification, PushSubscription, ActivityLog, OrderAssignments };
