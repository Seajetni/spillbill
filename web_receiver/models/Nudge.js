const mongoose = require('mongoose');

const NudgeSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    targetName: { type: String, required: true },
    senderName: { type: String, default: 'ป๊อป' },
    billTitle: { type: String, required: true },
    amount: { type: Number, required: true },
    transcript: { type: String, default: '' },
    persona: { type: String, default: 'น้องนุ่ม' },
    promptPayNumber: { type: String, default: '081-234-5678' },
    audioBase64: { type: String, default: null }, // Base64 audio if recorded/synthesized
    audioUrl: { type: String, default: null },
    durationSeconds: { type: Number, default: 8 },
    status: {
      type: String,
      enum: ['pending', 'paid', 'deferred', 'cancelled'],
      default: 'pending',
    },
    replyMessage: { type: String, default: null },
    paidAt: { type: Date, default: null },
  },
  {
    timestamps: true,
  }
);

// Prevent re-compiling model in serverless environment
module.exports = mongoose.models.Nudge || mongoose.model('Nudge', NudgeSchema);
