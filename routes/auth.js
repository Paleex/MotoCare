
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../Models/User');

const router = express.Router();

// REGISTER
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        status: false,
        message: 'Nama, email, dan password wajib diisi'
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        status: false,
        message: 'Password minimal 8 karakter'
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({
      email: normalizedEmail
    });

    if (existingUser) {
      return res.status(409).json({
        status: false,
        message: 'Email sudah terdaftar'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword
    });

    return res.status(201).json({
      status: true,
      message: 'Registrasi berhasil',
      data: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Register error:', error.message);
    return res.status(500).json({
      status: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

// LOGIN
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        status: false,
        message: 'Email dan password wajib diisi'
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase()
    }).select('+password');

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({
        status: false,
        message: 'Email atau password salah'
      });
    }

    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET belum diatur');
    }

    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.json({
      status: true,
      message: 'Login berhasil',
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({
      status: false,
      message: 'Terjadi kesalahan pada server'
    });
  }
});

module.exports = router;
