import { Box, Chip, CircularProgress, Container, Grid, Paper, Typography } from '@mui/material';
import { useEffect, useState } from 'react';

import { API_ENDPOINTS } from '../config/api';
import api from '../services/api';

const OrdersPage = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    try {
      const response = await api.get(API_ENDPOINTS.ORDERS);
      setOrders(response.data.orders);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      pending: 'warning',
      processing: 'info',
      shipped: 'primary',
      delivered: 'success',
      cancelled: 'error'
    };
    return colors[status] || 'default';
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  if (orders.length === 0) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, textAlign: 'center' }}>
        <Typography variant="h5">No orders yet</Typography>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" gutterBottom>
        My Orders
      </Typography>

      {orders.map((order) => (
        <Paper key={order.id} sx={{ p: 3, mb: 3 }}>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <Typography variant="h6">Order #{order.id.slice(0, 8)}</Typography>
              <Typography variant="body2" color="text.secondary">
                {new Date(order.created_at).toLocaleDateString()}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} sx={{ textAlign: { sm: 'right' } }}>
              <Chip label={order.status} color={getStatusColor(order.status)} />
              <Typography variant="h6" sx={{ mt: 1 }}>
                ${parseFloat(order.total_amount).toFixed(2)}
              </Typography>
            </Grid>
          </Grid>

          <Box sx={{ mt: 2 }}>
            <Typography variant="subtitle2" gutterBottom>
              Items:
            </Typography>
            {order.items.map((item) => (
              <Box key={item.id} display="flex" justifyContent="space-between" mb={1}>
                <Typography variant="body2">
                  {item.product.name} x {item.quantity}
                </Typography>
                <Typography variant="body2">
                  ${(parseFloat(item.price_at_purchase) * item.quantity).toFixed(2)}
                </Typography>
              </Box>
            ))}
          </Box>

          {order.shipping_address && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="subtitle2">Shipping Address:</Typography>
              <Typography variant="body2" color="text.secondary">
                {order.shipping_address}
              </Typography>
            </Box>
          )}
        </Paper>
      ))}
    </Container>
  );
};

export default OrdersPage;

// Made with Bob
