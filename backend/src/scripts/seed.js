require('dotenv').config();
const { sequelize, User, Product } = require('../models');
const bcrypt = require('bcryptjs');

const seedData = async () => {
  try {
    console.log('Starting database seed...');

    // Sync database
    await sequelize.sync({ force: true });
    console.log('Database synchronized.');

    // Create admin user
    const adminPassword = await bcrypt.hash('admin123', 10);
    const admin = await User.create({
      email: 'admin@example.com',
      password_hash: adminPassword,
      first_name: 'Admin',
      last_name: 'User',
      is_admin: true
    });
    console.log('Admin user created:', admin.email);

    // Create regular user
    const userPassword = await bcrypt.hash('user123', 10);
    const user = await User.create({
      email: 'user@example.com',
      password_hash: userPassword,
      first_name: 'John',
      last_name: 'Doe',
      is_admin: false
    });
    console.log('Regular user created:', user.email);

    // Create sample products
    const products = [
      {
        name: 'Wireless Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        price: 99.99,
        stock_quantity: 50,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500'
      },
      {
        name: 'Smart Watch',
        description: 'Feature-rich smartwatch with fitness tracking',
        price: 199.99,
        stock_quantity: 30,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500'
      },
      {
        name: 'Laptop Backpack',
        description: 'Durable backpack with laptop compartment',
        price: 49.99,
        stock_quantity: 100,
        category: 'Accessories',
        image_url: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500'
      },
      {
        name: 'USB-C Hub',
        description: 'Multi-port USB-C hub with HDMI and USB 3.0',
        price: 39.99,
        stock_quantity: 75,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1625948515291-69613efd103f?w=500'
      },
      {
        name: 'Mechanical Keyboard',
        description: 'RGB mechanical keyboard with blue switches',
        price: 129.99,
        stock_quantity: 40,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500'
      },
      {
        name: 'Wireless Mouse',
        description: 'Ergonomic wireless mouse with precision tracking',
        price: 29.99,
        stock_quantity: 80,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=500'
      },
      {
        name: 'Phone Stand',
        description: 'Adjustable phone stand for desk',
        price: 19.99,
        stock_quantity: 150,
        category: 'Accessories',
        image_url: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=500'
      },
      {
        name: 'Webcam HD',
        description: '1080p HD webcam with built-in microphone',
        price: 79.99,
        stock_quantity: 45,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1587825140708-dfaf72ae4b04?w=500'
      },
      {
        name: 'Desk Lamp',
        description: 'LED desk lamp with adjustable brightness',
        price: 34.99,
        stock_quantity: 60,
        category: 'Accessories',
        image_url: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=500'
      },
      {
        name: 'Cable Organizer',
        description: 'Cable management system for desk',
        price: 14.99,
        stock_quantity: 200,
        category: 'Accessories',
        image_url: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500'
      },
      {
        name: 'Portable SSD 1TB',
        description: 'Fast portable SSD with USB-C connection',
        price: 149.99,
        stock_quantity: 35,
        category: 'Electronics',
        image_url: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=500'
      },
      {
        name: 'Monitor Stand',
        description: 'Adjustable monitor stand with storage',
        price: 44.99,
        stock_quantity: 55,
        category: 'Accessories',
        image_url: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=500'
      }
    ];

    for (const productData of products) {
      const product = await Product.create(productData);
      console.log('Product created:', product.name);
    }

    console.log('\nSeed completed successfully!');
    console.log('\nTest credentials:');
    console.log('Admin - Email: admin@example.com, Password: admin123');
    console.log('User - Email: user@example.com, Password: user123');
    
    process.exit(0);
  } catch (error) {
    console.error('Seed error:', error);
    process.exit(1);
  }
};

seedData();

// Made with Bob
