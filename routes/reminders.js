
const express = require('express');
const mongoose = require('mongoose');

const router = express.Router();

const Reminder = require('../models/Reminder');
const Motor = require('../models/motor');
const auth = require('../middleware/auth');

// Semua endpoint memerlukan login
router.use(auth);

// GET /api/reminders
// Mengambil pengingat milik pengguna yang login
router.get('/', async (req, res) => {
  try {
    const reminders = await Reminder.find({
      user_id: req.userId,
    })
      .populate('motor_id', 'merk model plat_nomor')
      .sort({ tanggal_jatuh_tempo: 1 });

    res.json({
      status: true,
      data: reminders,
    });
  } catch (error) {
    console.error('Gagal mengambil pengingat:', error);
    res.status(500).json({
      status: false,
      message: 'Gagal mengambil data pengingat',
    });
  }
});

// POST /api/reminders
// Membuat pengingat baru
router.post('/', async (req, res) => {
  try {
    const {
      motor_id,
      jenis_servis,
      tanggal_jatuh_tempo,
      kilometer_target,
      catatan,
    } = req.body;

    if (
      !motor_id ||
      !mongoose.isValidObjectId(motor_id) ||
      !jenis_servis?.trim() ||
      !tanggal_jatuh_tempo
    ) {
      return res.status(400).json({
        status: false,
        message: 'Motor, jenis servis, dan tanggal wajib diisi',
      });
    }

    const tanggal = new Date(tanggal_jatuh_tempo);

    if (Number.isNaN(tanggal.getTime())) {
      return res.status(400).json({
        status: false,
        message: 'Format tanggal tidak valid',
      });
    }

    let targetKm = null;

    if (
      kilometer_target !== undefined &&
      kilometer_target !== null &&
      kilometer_target !== ''
    ) {
      targetKm = Number(kilometer_target);

      if (!Number.isFinite(targetKm) || targetKm < 0) {
        return res.status(400).json({
          status: false,
          message: 'Target kilometer harus berupa angka positif',
        });
      }
    }

    // Pastikan motor benar-benar milik pengguna yang login
    const motor = await Motor.findOne({
      _id: motor_id,
      user_id: req.userId,
    });

    if (!motor) {
      return res.status(404).json({
        status: false,
        message: 'Motor tidak ditemukan',
      });
    }

    const reminder = await Reminder.create({
      user_id: req.userId,
      motor_id,
      jenis_servis: jenis_servis.trim(),
      tanggal_jatuh_tempo: tanggal,
      kilometer_target: targetKm,
      catatan: catatan?.trim() || '',
    });

    const savedReminder = await Reminder.findById(reminder._id)
      .populate('motor_id', 'merk model plat_nomor');

    res.status(201).json({
      status: true,
      message: 'Pengingat berhasil ditambahkan',
      data: savedReminder,
    });
  } catch (error) {
    console.error('Gagal menambahkan pengingat:', error);
    res.status(500).json({
      status: false,
      message: 'Gagal menambahkan pengingat',
    });
  }
});

// PUT /api/reminders/:id/status
// Mengubah status pengingat menjadi aktif atau selesai
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        status: false,
        message: 'ID pengingat tidak valid',
      });
    }

    if (!['aktif', 'selesai'].includes(status)) {
      return res.status(400).json({
        status: false,
        message: 'Status harus aktif atau selesai',
      });
    }

    const reminder = await Reminder.findOneAndUpdate(
      { _id: id, user_id: req.userId },
      { status },
      { new: true, runValidators: true }
    ).populate('motor_id', 'merk model plat_nomor');

    if (!reminder) {
      return res.status(404).json({
        status: false,
        message: 'Pengingat tidak ditemukan',
      });
    }

    res.json({
      status: true,
      message: 'Status pengingat berhasil diperbarui',
      data: reminder,
    });
  } catch (error) {
    console.error('Gagal mengubah status:', error);
    res.status(500).json({
      status: false,
      message: 'Gagal mengubah status pengingat',
    });
  }
});

// DELETE /api/reminders/:id
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        status: false,
        message: 'ID pengingat tidak valid',
      });
    }

    const reminder = await Reminder.findOneAndDelete({
      _id: id,
      user_id: req.userId,
    });

    if (!reminder) {
      return res.status(404).json({
        status: false,
        message: 'Pengingat tidak ditemukan',
      });
    }

    res.json({
      status: true,
      message: 'Pengingat berhasil dihapus',
    });
  } catch (error) {
    console.error('Gagal menghapus pengingat:', error);
    res.status(500).json({
      status: false,
      message: 'Gagal menghapus pengingat',
    });
  }
});

module.exports = router;
