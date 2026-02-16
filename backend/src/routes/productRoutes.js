const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const { auth, adminAuth } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.get('/', productController.getAllProducts);
router.get('/categories', productController.getCategories);
router.get('/category/:category', productController.getProductsByCategory);
router.get('/:id', productController.getProductById);
router.post('/', adminAuth, validate(schemas.product), productController.createProduct);
router.put('/:id', adminAuth, validate(schemas.updateProduct), productController.updateProduct);
router.delete('/:id', adminAuth, productController.deleteProduct);

module.exports = router;

// Made with Bob
