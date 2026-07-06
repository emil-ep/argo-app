import {
  Alert,
  Box,
  Button,
  Chip,
  Container,
  Divider,
  FormControl,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Slider,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { useEffect, useRef, useState } from 'react';

import api from '../services/api';

const STATUS_CODES = [400, 401, 403, 404, 409, 422, 429, 500, 502, 503, 504];

const ErrorSimulatorPage = () => {
  const [statusCode, setStatusCode] = useState(500);
  const [message, setMessage] = useState('Simulated error for Instana testing');
  const [repeat, setRepeat] = useState(false);
  const [intervalSec, setIntervalSec] = useState(5);
  const [log, setLog] = useState([]);
  const [running, setRunning] = useState(false);
  const timerRef = useRef(null);
  const logEndRef = useRef(null);

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [log]);

  useEffect(() => {
    return () => clearInterval(timerRef.current);
  }, []);

  const addLog = (code, msg, ok) => {
    const ts = new Date().toLocaleTimeString();
    setLog((prev) => [...prev.slice(-99), { ts, code, msg, ok }]);
  };

  const fire = async () => {
    try {
      await api.post('/api/simulate-error', { statusCode, message });
      addLog(statusCode, message, true);
    } catch (err) {
      const code = err.response?.status ?? statusCode;
      addLog(code, err.response?.data?.error ?? message, false);
    }
  };

  const handleFire = () => {
    fire();
  };

  const handleToggleRepeat = () => {
    if (running) {
      clearInterval(timerRef.current);
      setRunning(false);
    } else {
      fire();
      timerRef.current = setInterval(fire, intervalSec * 1000);
      setRunning(true);
    }
  };

  return (
    <Container maxWidth="md" sx={{ mt: 4, mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Typography variant="h4" gutterBottom>
          Error Simulator
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
          Trigger HTTP errors against the backend. Each request is traced by Instana and marked as erroneous.
        </Typography>

        <Stack spacing={3}>
          {/* Status code selector */}
          <FormControl fullWidth>
            <InputLabel>HTTP Status Code</InputLabel>
            <Select
              value={statusCode}
              label="HTTP Status Code"
              onChange={(e) => setStatusCode(e.target.value)}
            >
              {STATUS_CODES.map((code) => (
                <MenuItem key={code} value={code}>
                  {code}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          {/* Message */}
          <TextField
            fullWidth
            label="Error Message"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />

          <Divider />

          {/* Repeat toggle */}
          <Box>
            <Typography gutterBottom>
              Repeat interval: <strong>{intervalSec}s</strong>
            </Typography>
            <Slider
              value={intervalSec}
              min={1}
              max={60}
              step={1}
              marks={[{ value: 1, label: '1s' }, { value: 30, label: '30s' }, { value: 60, label: '60s' }]}
              onChange={(_, v) => setIntervalSec(v)}
              disabled={running}
            />
          </Box>

          {/* Action buttons */}
          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              color="error"
              size="large"
              onClick={handleFire}
              disabled={running}
            >
              Fire Once
            </Button>
            <Button
              variant={running ? 'outlined' : 'contained'}
              color={running ? 'warning' : 'secondary'}
              size="large"
              onClick={handleToggleRepeat}
            >
              {running ? `Stop (repeating every ${intervalSec}s)` : 'Start Repeating'}
            </Button>
          </Stack>

          {running && (
            <Alert severity="warning">
              Firing <strong>{statusCode}</strong> every <strong>{intervalSec}s</strong> — click Stop to cancel.
            </Alert>
          )}

          {/* Log */}
          {log.length > 0 && (
            <Box>
              <Typography variant="subtitle2" gutterBottom>Request log</Typography>
              <Box
                sx={{
                  maxHeight: 220,
                  overflowY: 'auto',
                  bgcolor: '#f5f5f5',
                  borderRadius: 1,
                  p: 1.5,
                  fontFamily: 'monospace',
                  fontSize: 13,
                }}
              >
                {log.map((entry, i) => (
                  <Box key={i} sx={{ mb: 0.5 }}>
                    <Chip
                      label={entry.code}
                      size="small"
                      color={entry.ok ? 'default' : 'error'}
                      sx={{ mr: 1, fontFamily: 'monospace' }}
                    />
                    <span style={{ color: '#555' }}>{entry.ts}</span>
                    {' — '}
                    {entry.msg}
                  </Box>
                ))}
                <div ref={logEndRef} />
              </Box>
            </Box>
          )}
        </Stack>
      </Paper>
    </Container>
  );
};

export default ErrorSimulatorPage;

// Made with Bob
