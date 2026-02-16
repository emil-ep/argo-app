import { AccountCircle, ShoppingCart } from '@mui/icons-material';
import { AppBar, Badge, Box, Button, IconButton, Toolbar, Typography } from '@mui/material';

import { useAuth } from '../context/AuthContext';
import { useCart } from '../context/CartContext';
import { useNavigate } from 'react-router-dom';

const Navbar = () => {
  const navigate = useNavigate();
  const { user, isAuthenticated, logout } = useAuth();
  const { cart } = useCart();

  const handleLogout = async () => {
    await logout();
    navigate('/');
  };

  return (
    <AppBar position="sticky">
      <Toolbar>
        <Typography
          variant="h6"
          component="div"
          sx={{ flexGrow: 1, cursor: 'pointer' }}
          onClick={() => navigate('/')}
        >
          E-Commerce Store
        </Typography>

        {isAuthenticated ? (
          <>
            <IconButton color="inherit" onClick={() => navigate('/cart')}>
              <Badge badgeContent={cart.count} color="error">
                <ShoppingCart />
              </Badge>
            </IconButton>
            <Button color="inherit" onClick={() => navigate('/orders')}>
              Orders
            </Button>
            <Box sx={{ display: 'flex', alignItems: 'center', ml: 2 }}>
              <AccountCircle sx={{ mr: 1 }} />
              <Typography variant="body2" sx={{ mr: 2 }}>
                {user?.first_name || user?.email}
              </Typography>
              <Button color="inherit" onClick={handleLogout}>
                Logout
              </Button>
            </Box>
          </>
        ) : (
          <>
            <Button color="inherit" onClick={() => navigate('/login')}>
              Login
            </Button>
            <Button color="inherit" onClick={() => navigate('/register')}>
              Register
            </Button>
          </>
        )}
      </Toolbar>
    </AppBar>
  );
};

export default Navbar;

// Made with Bob
