import { Add, Delete, Remove } from '@mui/icons-material';
import { Box, Button, Container, Grid, IconButton, Paper, Typography } from '@mui/material';

import { useCart } from '../context/CartContext';
import { useNavigate } from 'react-router-dom';

const CartPage = () => {
  const navigate = useNavigate();
  const { cart, updateCartItem, removeFromCart, loading } = useCart();

  const handleUpdateQuantity = async (itemId, currentQuantity, change) => {
    const newQuantity = currentQuantity + change;
    if (newQuantity > 0) {
      await updateCartItem(itemId, newQuantity);
    }
  };

  const handleRemove = async (itemId) => {
    if (window.confirm('Remove this item from cart?')) {
      await removeFromCart(itemId);
    }
  };

  

  if (cart.items.length === 0) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, textAlign: 'center' }}>
        <Typography variant="h5" gutterBottom>
          Your cart is empty
        </Typography>
        <Button variant="contained" onClick={() => navigate('/')} sx={{ mt: 2 }}>
          Continue Shopping
        </Button>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" gutterBottom>
        Shopping Cart
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          {cart.items.map((item) => (
            <Paper key={item.id} sx={{ p: 2, mb: 2 }}>
              <Grid container spacing={2} alignItems="center">
                <Grid item xs={3}>
                  <img
                    src={item.product.image_url || 'https://via.placeholder.com/150'}
                    alt={item.product.name}
                    style={{ width: '100%', height: 'auto' }}
                  />
                </Grid>
                <Grid item xs={4}>
                  <Typography variant="h6">{item.product.name}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    ${parseFloat(item.product.price).toFixed(2)} each
                  </Typography>
                </Grid>
                <Grid item xs={3}>
                  <Box display="flex" alignItems="center">
                    <IconButton
                      size="small"
                      onClick={() => handleUpdateQuantity(item.id, item.quantity, -1)}
                      disabled={loading}
                    >
                      <Remove />
                    </IconButton>
                    <Typography sx={{ mx: 2 }}>{item.quantity}</Typography>
                    <IconButton
                      size="small"
                      onClick={() => handleUpdateQuantity(item.id, item.quantity, 1)}
                      disabled={loading || item.quantity >= item.product.stock_quantity}
                    >
                      <Add />
                    </IconButton>
                  </Box>
                </Grid>
                <Grid item xs={2}>
                  <Box display="flex" flexDirection="column" alignItems="flex-end">
                    <Typography variant="h6">
                      ${(parseFloat(item.product.price) * item.quantity).toFixed(2)}
                    </Typography>
                    <IconButton
                      color="error"
                      onClick={() => handleRemove(item.id)}
                      disabled={loading}
                    >
                      <Delete />
                    </IconButton>
                  </Box>
                </Grid>
              </Grid>
            </Paper>
          ))}
        </Grid>

        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 3, position: 'sticky', top: 80 }}>
            <Typography variant="h5" gutterBottom>
              Order Summary
            </Typography>
            <Box sx={{ my: 2 }}>
              <Box display="flex" justifyContent="space-between" mb={1}>
                <Typography>Items ({cart.count}):</Typography>
                <Typography>${cart.total}</Typography>
              </Box>
              <Box display="flex" justifyContent="space-between" mb={2}>
                <Typography variant="h6">Total:</Typography>
                <Typography variant="h6">${cart.total}</Typography>
              </Box>
            </Box>
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={() => navigate('/checkout')}
            >
              Proceed to Checkout
            </Button>
          </Paper>
        </Grid>
      </Grid>
    </Container>
  );
};

export default CartPage;

// Made with Bob
