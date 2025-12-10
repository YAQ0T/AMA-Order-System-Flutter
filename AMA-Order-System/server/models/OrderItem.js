const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    const OrderItem = sequelize.define('OrderItem', {
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        quantity: {
            type: DataTypes.INTEGER,
            allowNull: false,
            defaultValue: 1
        },
        status: {
            type: DataTypes.ENUM('collected', 'unavailable'),
            allowNull: true,
            defaultValue: null
        },
        price: {
            type: DataTypes.DECIMAL(10, 2),
            allowNull: true,
            defaultValue: null
        }
    });

    return OrderItem;
};
