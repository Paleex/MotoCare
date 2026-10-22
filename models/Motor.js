
const mongoose = require('mongoose');

const motorSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    merk: {
      type: String,
      required: true,
      trim: true,
    },
    model: {
      type: String,
      required: true,
      trim: true,
    },
    tahun: {
      type: Number,
      required: true,
    },
    cc: {
      type: Number,
      required: true,
    },
    plat_nomor: {
      type: String,
      required: true,
      trim: true,
    },
    kilometer: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Motor', motorSchema);
