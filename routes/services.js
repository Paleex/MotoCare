
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Service = require('../models/Service');
const Motor = require('../models/motor');
const auth = require('../middleware/auth');

// GET: Menampilkan riwayat servis pengguna
router.get('/', auth, async (req, res) => {
  try {
    const services = await Service.find({
      user_id: req.userId,
    })
      .populate('motor_id', 'merk model plat_nomor')
      .sort({ tanggal_servis: -1 });

    res.status(200).json({
      status: true,
      data: services,
    });
  } catch (error) {
    console.error('Get services:', error.message);

    res.status(500).json({
      status: false,
      message: 'Gagal mengambil riwayat servis',
    });
  }
});

// POST: Menambahkan riwayat servis
router.post('/', auth, async (req, res) => {
  try {
    const {
      motor_id,
      tanggal_servis,
      jenis_servis,
      kilometer,
      biaya,
      catatan,
    } = req.body;

    if (
      !motor_id ||
      !mongoose.isValidObjectId(motor_id) ||
      !tanggal_servis ||
      !jenis_servis?.trim() ||
      kilometer == null ||
      biaya == null
    ) {
      return res.status(400).json({
        status: false,
        message: 'Motor, tanggal, jenis servis, kilometer, dan biaya wajib diisi dengan benar',
      });
    }

    const parsedDate = new Date(tanggal_servis);
    const parsedKilometer = Number(kilometer);
    const parsedBiaya = Number(biaya);

    if (
      Number.isNaN(parsedDate.getTime()) ||
      !Number.isFinite(parsedKilometer) ||
      !Number.isFinite(parsedBiaya) ||
      parsedKilometer < 0 ||
      parsedBiaya < 0
    ) {
      return res.status(400).json({
        status: false,
        message: 'Tanggal, kilometer, atau biaya tidak valid',
      });
    }

    // Pastikan motor memang milik pengguna yang sedang login.
    const motor = await Motor.findOne({
      _id: motor_id,
      user_id: req.userId,
    });

    if (!motor) {
      return res.status(404).json({
        status: false,
        message: 'Motor tidak ditemukan pada akun ini',
      });
    }

    const service = await Service.create({
      user_id: req.userId,
      motor_id,
      tanggal_servis: parsedDate,
      jenis_servis: jenis_servis.trim(),
      kilometer: parsedKilometer,
      biaya: parsedBiaya,
      catatan: catatan?.trim() ?? '',
    });

    const savedService = await Service.findById(service._id)
      .populate('motor_id', 'merk model plat_nomor');

    return res.status(201).json({
      status: true,
      message: 'Riwayat servis berhasil ditambahkan',
      data: savedService,
    });
  } catch (error) {
    console.error('Create service:', error.message);

    return res.status(500).json({
      status: false,
      message: 'Gagal menambahkan riwayat servis',
    });
  }
});

module.exports = router;
