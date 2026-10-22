
const express = require('express');
const mongoose = require('mongoose');

const Expense = require('../models/Expense');
const Motor = require('../models/motor');
const auth = require('../middleware/auth');

const router = express.Router();

router.use(auth);

// GET: daftar biaya milik pengguna
router.get('/', async (req, res) => {
  try {
    const expenses = await Expense.find({
      user_id: req.userId,
    })
      .populate('motor_id', 'merk model plat_nomor')
      .sort({ tanggal: -1 });

    res.json({
      status: true,
      data: expenses,
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: 'Gagal mengambil catatan biaya',
    });
  }
});

// POST: tambah catatan biaya
router.post('/', async (req, res) => {
  try {
    const {
      motor_id,
      kategori,
      tanggal,
      biaya,
      keterangan,
    } = req.body;

    if (
      !motor_id ||
      !mongoose.Types.ObjectId.isValid(motor_id) ||
      !kategori?.trim() ||
      !tanggal ||
      biaya === undefined ||
      biaya === null ||
      biaya === ''
    ) {
      return res.status(400).json({
        status: false,
        message: 'Data catatan biaya belum lengkap',
      });
    }

    const parsedDate = new Date(tanggal);
    const parsedBiaya = Number(biaya);

    if (
      Number.isNaN(parsedDate.getTime()) ||
      !Number.isFinite(parsedBiaya) ||
      parsedBiaya < 0
    ) {
      return res.status(400).json({
        status: false,
        message: 'Tanggal atau nominal biaya tidak valid',
      });
    }

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

    const expense = await Expense.create({
      user_id: req.userId,
      motor_id,
      kategori: kategori.trim(),
      tanggal: parsedDate,
      biaya: parsedBiaya,
      keterangan: keterangan ?? '',
    });

    const savedExpense = await Expense.findById(expense._id)
      .populate('motor_id', 'merk model plat_nomor');

    res.status(201).json({
      status: true,
      message: 'Catatan biaya berhasil ditambahkan',
      data: savedExpense,
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: 'Gagal menambahkan catatan biaya',
    });
  }
});

// DELETE: hapus catatan biaya milik pengguna
router.delete('/:id', async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({
        status: false,
        message: 'ID catatan biaya tidak valid',
      });
    }

    const expense = await Expense.findOneAndDelete({
      _id: req.params.id,
      user_id: req.userId,
    });

    if (!expense) {
      return res.status(404).json({
        status: false,
        message: 'Catatan biaya tidak ditemukan',
      });
    }

    res.json({
      status: true,
      message: 'Catatan biaya berhasil dihapus',
    });
  } catch (error) {
    res.status(500).json({
      status: false,
      message: 'Gagal menghapus catatan biaya',
    });
  }
});

module.exports = router;
