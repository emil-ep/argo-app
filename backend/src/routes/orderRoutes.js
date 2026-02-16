const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { auth, adminAuth } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.get('/', auth, orderController.getOrders);
router.get('/all', adminAuth, orderController.getAllOrders);
router.get('/:id', auth, orderController.getOrderById);
router.post('/', auth, validate(schemas.order), orderController.createOrder);
router.put('/:id/status', adminAuth, validate(schemas.updateOrderStatus), orderController.updateOrderStatus);

module.exports = router;

// Made with Bob
