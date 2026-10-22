
const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema(
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

    jenis_servis: {
      type: String,
      required: true,
      trim: true,
    },

    tanggal_jatuh_tempo: {
      type: Date,
      required: true,
    },

    kilometer_target: {
      type: Number,
      min: 0,
      default: null,
    },

    catatan: {
      type: String,
      trim: true,
      default: '',
    },

    status: {
      type: String,
      enum: ['aktif', 'selesai'],
      default: 'aktif',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Reminder', reminderSchema);
