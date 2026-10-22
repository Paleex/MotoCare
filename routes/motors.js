
const express = require('express');
const mongoose = require('mongoose');
const Motor = require('../models/motor');
const auth = require('../middleware/auth');

const router = express.Router();

// Semua endpoint motor wajib login
router.use(auth);

// GET: daftar motor milik pengguna yang login
router.get('/', async (req, res) => {
  try {
    const motors = await Motor.find({
      user_id: req.userId,
    }).sort({ createdAt: -1 });

    res.json({
      status: true,
      message: 'Data motor berhasil diambil',
      data: motors,
    });
  } catch (error) {
    console.error('Get motors:', error.message);
    res.status(500).json({
      status: false,
      message: 'Gagal mengambil data motor',
    });
  }
});

// POST: tambah motor
router.post('/', auth, async (req, res) => {
  try {
    const {
      merk,
      model,
      tahun,
      cc,
      plat_nomor,
      kilometer,
    } = req.body;

    if (
      !merk?.trim() ||
      !model?.trim() ||
      !plat_nomor?.trim() ||
      tahun == null ||
      cc == null
    ) {
      return res.status(400).json({
        status: false,
        message: 'Merk, model, tahun, cc, dan plat nomor wajib diisi',
      });
    }

    const motor = await Motor.create({
      user_id: req.userId,
      merk,
      model,
      tahun,
      cc,
      plat_nomor,
      kilometer: kilometer ?? 0,
    });

    res.status(201).json({
      status: true,
      message: 'Motor berhasil ditambahkan',
      data: motor,
    });
  } catch (error) {
    console.error('Create motor:', error.message);
    res.status(500).json({
      status: false,
      message: 'Gagal menambahkan motor',
    });
  }
});

// PUT: ubah motor milik pengguna
router.put('/:id', auth, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        status: false,
        message: 'ID motor tidak valid',
      });
    }

    const allowed = [
      'merk', 'model', 'tahun', 'cc',
      'plat_nomor', 'kilometer',
    ];

    const updates = {};
    for (const key of allowed) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    const motor = await Motor.findOneAndUpdate(
      { _id: req.params.id, user_id: req.userId },
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!motor) {
      return res.status(404).json({
        status: false,
        message: 'Motor tidak ditemukan',
      });
    }

    res.json({
      status: true,
      message: 'Motor berhasil diperbarui',
      data: motor,
    });
  } catch (error) {
    console.error('Update motor:', error.message);
    res.status(400).json({
      status: false,
      message: 'Gagal memperbarui motor',
    });
  }
});

// DELETE: hapus motor milik pengguna
router.delete('/:id', auth, async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        status: false,
        message: 'ID motor tidak valid',
      });
    }

    const motor = await Motor.findOneAndDelete({
      _id: req.params.id,
      user_id: req.userId,
    });

    if (!motor) {
      return res.status(404).json({
        status: false,
        message: 'Motor tidak ditemukan',
      });
    }

    res.json({
      status: true,
      message: 'Motor berhasil dihapus',
    });
  } catch (error) {
    console.error('Delete motor:', error.message);
    res.status(500).json({
      status: false,
      message: 'Gagal menghapus motor',
    });
  }
});

module.exports = router;
