
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const motorRoutes = require('./routes/motors');
const serviceRoutes = require('./routes/services');
const reminderRoutes = require('./routes/reminders');
const expenseRoutes = require('./routes/expenses');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
const corsOptions = {
  origin: (origin, callback) => {
    // Izinkan request tanpa origin, misalnya dari Postman.
    if (!origin) {
      return callback(null, true);
    }

    const allowedOrigin =
      /^http:\/\/(localhost|127\.0\.0\.1):\d+$/.test(origin);

    if (allowedOrigin) {
      return callback(null, true);
    }

    return callback(new Error('Origin tidak diizinkan oleh CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));

// Route autentikasi
app.use('/api', authRoutes);

app.use('/api/motors', motorRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/expenses', expenseRoutes);

app.get('/', (req, res) => {
  res.json({
    status: true,
    message: 'MotoCare API Node.js aktif'
  });
});

async function startServer() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Atlas berhasil terhubung!');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`MotoCare API berjalan di port ${PORT}`);
    });
  } catch (error) {
    console.error('Gagal menghubungkan MongoDB:', error.message);
    process.exit(1);
  }
}

startServer();
