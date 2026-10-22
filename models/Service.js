
const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },

    motor_id: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'Motor',
    },

    tanggal_servis: {
      type: Date,
      required: true,
    },

    jenis_servis: {
      type: String,
      required: true,
      trim: true,
    },

    kilometer: {
      type: Number,
      required: true,
      min: 0,
    },

    biaya: {
      type: Number,
      required: true,
      min: 0,
    },

    catatan: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Service', serviceSchema);
