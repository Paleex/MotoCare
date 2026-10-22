
const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    motor_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Motor',
      required: true,
    },
    kategori: {
      type: String,
      required: true,
      trim: true,
    },
    tanggal: {
      type: Date,
      required: true,
    },
    biaya: {
      type: Number,
      required: true,
      min: 0,
    },
    keterangan: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Expense', expenseSchema);
