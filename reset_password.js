
require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./Models/User');

async function resetPassword() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);

    const email = 'fahkri@example.com';
    const passwordBaru = 'MotoCare2026!';

    const user = await User.findOne({ email });

    if (!user) {
      console.log('User tidak ditemukan:', email);
      return;
    }

    user.password = await bcrypt.hash(passwordBaru, 10);
    await user.save();

    console.log('Password berhasil direset!');
    console.log('Email:', email);
    console.log('Gunakan password baru yang sudah ditentukan di file ini.');
  } catch (error) {
    console.error('Gagal reset password:', error.message);
  } finally {
    await mongoose.disconnect();
  }
}

resetPassword();
