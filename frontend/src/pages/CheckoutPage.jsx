import { Alert, Box, Button, Container, Paper, TextField, Typography } from '@mui/material';

import { API_ENDPOINTS } from '../config/api';
import api from '../services/api';
import { useCart } from '../context/CartContext';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';

const CheckoutPage = () => {
  const [shippingAddress, setShippingAddress] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { cart, refreshCart } = useCart();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await api.post(API_ENDPOINTS.ORDERS, { shipping_address: shippingAddress });
      await refreshCart();
      alert('Order placed successfully!');
      navigate('/orders');
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to place order');
    } finally {
      setLoading(false);
    }
  };

  if (cart.items.length === 0) {
    return (
      <Container maxWidth="sm" sx={{ mt: 4, textAlign: 'center' }}>
        <Typography variant="h5">Your cart is empty</Typography>
        <Button variant="contained" onClick={() => navigate('/')} sx={{ mt: 2 }}>
          Continue Shopping
        </Button>
      </Container>
    );
  }

  return (
    <Container maxWidth="sm" sx={{ mt: 4, mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Typography variant="h4" gutterBottom>
          Checkout
        </Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Box sx={{ mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Order Summary
          </Typography>
          {cart.items.map((item) => (
            <Box key={item.id} display="flex" justifyContent="space-between" mb={1}>
              <Typography>
                {item.product.name} x {item.quantity}
              </Typography>
              <Typography>
                ${(parseFloat(item.product.price) * item.quantity).toFixed(2)}
              </Typography>
            </Box>
          ))}
          <Box display="flex" justifyContent="space-between" mt={2} pt={2} borderTop={1} borderColor="divider">
            <Typography variant="h6">Total:</Typography>
            <Typography variant="h6">${cart.total}</Typography>
          </Box>
        </Box>

        <Box component="form" onSubmit={handleSubmit}>
          <TextField
            fullWidth
            label="Shipping Address"
            multiline
            rows={4}
            value={shippingAddress}
            onChange={(e) => setShippingAddress(e.target.value)}
            required
            margin="normal"
          />
          <Button
            fullWidth
            type="submit"
            variant="contained"
            size="large"
            sx={{ mt: 3 }}
            disabled={loading}
          >
            {loading ? 'Placing Order...' : 'Place Order'}
          </Button>
        </Box>
      </Paper>
    </Container>
  );
};

export default CheckoutPage;

// Made with Bob
