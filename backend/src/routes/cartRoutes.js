const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');
const { auth } = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

router.get('/', auth, cartController.getCart);
router.post('/items', auth, validate(schemas.cartItem), cartController.addToCart);
router.put('/items/:id', auth, validate(schemas.updateCartItem), cartController.updateCartItem);
router.delete('/items/:id', auth, cartController.removeFromCart);
router.delete('/', auth, cartController.clearCart);

module.exports = router;

// Made with Bob
