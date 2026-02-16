const Joi = require('joi');

const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      return res.status(400).json({ errors });
    }
    
    next();
  };
};

// Validation schemas
const schemas = {
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    first_name: Joi.string().min(2).max(100),
    last_name: Joi.string().min(2).max(100)
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  product: Joi.object({
    name: Joi.string().min(1).max(255).required(),
    description: Joi.string().allow('', null),
    price: Joi.number().min(0).required(),
    stock_quantity: Joi.number().integer().min(0).required(),
    image_url: Joi.string().uri().allow('', null),
    category: Joi.string().max(100).allow('', null)
  }),

  updateProduct: Joi.object({
    name: Joi.string().min(1).max(255),
    description: Joi.string().allow('', null),
    price: Joi.number().min(0),
    stock_quantity: Joi.number().integer().min(0),
    image_url: Joi.string().uri().allow('', null),
    category: Joi.string().max(100).allow('', null)
  }),

  cartItem: Joi.object({
    product_id: Joi.string().uuid().required(),
    quantity: Joi.number().integer().min(1).required()
  }),

  updateCartItem: Joi.object({
    quantity: Joi.number().integer().min(1).required()
  }),

  order: Joi.object({
    shipping_address: Joi.string().required()
  }),

  updateOrderStatus: Joi.object({
    status: Joi.string().valid('pending', 'processing', 'shipped', 'delivered', 'cancelled').required()
  })
};

module.exports = { validate, schemas };

// Made with Bob
