// Initialize MongoDB database
db = db.getSiblingDB('ewarranty');

// Create collections
db.createCollection('warranties');
db.createCollection('products');
db.createCollection('users');

print('Database initialized successfully');