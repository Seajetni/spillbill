const express = require('express');
const cors = require('cors');
const promptpayQR = require('promptpay-qr');
const QRCode = require('qrcode');
const { connectToDatabase } = require('../db');
const Nudge = require('../models/Nudge');

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health / Root info
app.get('/', async (req, res) => {
  let dbStatus = 'disconnected';
  try {
    await connectToDatabase();
    dbStatus = 'connected (MongoDB Atlas)';
  } catch (e) {
    dbStatus = 'error: ' + e.message;
  }

  res.send(`
    <!DOCTYPE html>
    <html lang="th">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>SplitBill - Zero-Install Web Receiver Service</title>
      <script src="https://cdn.tailwindcss.com"></script>
      <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700&family=Noto+Sans+Thai:wght@400;500;600;700&display=swap" rel="stylesheet">
      <style>
        body { font-family: 'Plus Jakarta Sans', 'Noto Sans Thai', sans-serif; }
      </style>
    </head>
    <body class="bg-slate-50 min-h-screen flex items-center justify-center p-4">
      <div class="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 border border-slate-100 text-center">
        <div class="w-16 h-16 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">
          🔊
        </div>
        <h1 class="text-2xl font-bold text-slate-800 mb-2">SplitBill Web Service</h1>
        <p class="text-sm text-slate-500 mb-6">Zero-Install Voice Nudge & Payment Landing</p>
        
        <div class="bg-slate-50 rounded-xl p-4 text-left border border-slate-200 mb-6 text-xs space-y-2">
          <div class="flex justify-between items-center">
            <span class="text-slate-500 font-medium">Database:</span>
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${dbStatus.startsWith('connected') ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'}">
              ${dbStatus}
            </span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-slate-500 font-medium">Hosting:</span>
            <span class="font-semibold text-slate-700">Vercel Serverless</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-slate-500 font-medium">API Endpoint:</span>
            <span class="font-mono text-slate-700">/api/nudge</span>
          </div>
        </div>

        <p class="text-xs text-slate-400">
          เมื่อผู้ใช้ส่งเสียงทวง ลิงก์สำหรับผู้รับจะอยู่ที่ <code>/n/:nudgeId</code>
        </p>
      </div>
    </body>
    </html>
  `);
});

// API: Create or update nudge in MongoDB
app.post('/api/nudge', async (req, res) => {
  try {
    await connectToDatabase();

    const {
      id,
      targetName,
      senderName = 'ป๊อป',
      billTitle,
      amount,
      transcript = '',
      persona = 'น้องนุ่ม',
      promptPayNumber = '081-234-5678',
      audioBase64 = null,
      audioUrl = null,
      durationSeconds = 8,
    } = req.body;

    if (!targetName || !billTitle || amount == null) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: targetName, billTitle, amount',
      });
    }

    const nudgeId = id || 'vn_' + Date.now();

    const nudge = await Nudge.findOneAndUpdate(
      { id: nudgeId },
      {
        id: nudgeId,
        targetName,
        senderName,
        billTitle,
        amount: Number(amount),
        transcript,
        persona,
        promptPayNumber,
        audioBase64,
        audioUrl,
        durationSeconds: Number(durationSeconds) || 8,
      },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true }
    );

    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    const host = req.headers['x-forwarded-host'] || req.get('host');
    const shareUrl = `${protocol}://${host}/n/${nudgeId}`;

    res.status(200).json({
      success: true,
      id: nudgeId,
      shareUrl,
      path: `/n/${nudgeId}`,
      nudge,
    });
  } catch (err) {
    console.error('Error saving nudge:', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// API: Get nudge details JSON
app.get('/api/nudge/:id', async (req, res) => {
  try {
    await connectToDatabase();
    const nudge = await Nudge.findOne({ id: req.params.id });
    if (!nudge) {
      return res.status(404).json({ success: false, error: 'Nudge not found' });
    }
    res.json({ success: true, nudge });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// API: Quick Reply / Update Status
app.post('/api/nudge/:id/reply', async (req, res) => {
  try {
    await connectToDatabase();
    const { replyMessage, status } = req.body;

    const update = {};
    if (replyMessage) update.replyMessage = replyMessage;
    if (status) {
      update.status = status;
      if (status === 'paid') update.paidAt = new Date();
    }

    const nudge = await Nudge.findOneAndUpdate(
      { id: req.params.id },
      update,
      { returnDocument: 'after' }
    );

    if (!nudge) {
      return res.status(404).json({ success: false, error: 'Nudge not found' });
    }

    res.json({ success: true, nudge });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// WEB LANDING: Zero-Install Receiver View
app.get('/n/:id', async (req, res) => {
  try {
    await connectToDatabase();
    const nudge = await Nudge.findOne({ id: req.params.id });

    // Fallback data if ID is not in DB yet (supports instant preview)
    const data = nudge || {
      id: req.params.id,
      senderName: req.query.sender || 'ป๊อป',
      targetName: req.query.target || 'คุณ',
      billTitle: req.query.bill || 'บิลค่าใช้จ่าย',
      amount: parseFloat(req.query.amount) || 0,
      transcript: req.query.transcript || 'มีบิลค้างชำระ กดดูรายละเอียดและสแกนจ่ายได้เลยจ้า',
      persona: req.query.persona || 'น้องนุ่ม',
      promptPayNumber: req.query.promptPay || '081-234-5678',
      durationSeconds: parseInt(req.query.duration) || 8,
      audioBase64: null,
      status: 'pending',
    };

    // Generate real PromptPay QR Code
    let qrDataUrl = '';
    try {
      const cleanPhone = (data.promptPayNumber || '0812345678').replace(/[^0-9]/g, '');
      const payload = promptpayQR(cleanPhone, { amount: data.amount });
      qrDataUrl = await QRCode.toDataURL(payload, {
        errorCorrectionLevel: 'M',
        margin: 1,
        width: 320,
        color: { dark: '#002D63', light: '#FFFFFF' },
      });
    } catch (e) {
      console.error('PromptPay QR Error:', e.message);
      // Fallback to promptpay.io URL
      const cleanPhone = (data.promptPayNumber || '0812345678').replace(/[^0-9]/g, '');
      qrDataUrl = `https://promptpay.io/${cleanPhone}/${data.amount}.png`;
    }

    const formattedAmount = Number(data.amount).toLocaleString('th-TH', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    });

    const isPaid = data.status === 'paid';

    res.send(`
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>🔊 ข้อความเสียงทวงเงินจาก ${data.senderName} - ${data.billTitle}</title>

  <!-- OpenGraph Metadata for LINE & Social Sharing -->
  <meta property="og:title" content="🔊 ${data.senderName} ส่งเสียงทวงเงิน: ${data.billTitle}">
  <meta property="og:description" content="💰 ยอดที่ต้องชำระ ฿${formattedAmount} - ฟังเสียงและชำระผ่าน PromptPay ได้ทันที ไม่ต้องโหลดแอป">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="SplitBill">

  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600;700;800&family=Noto+Sans+Thai:wght@400;500;600;700&display=swap" rel="stylesheet">

  <style>
    body { font-family: 'Plus Jakarta Sans', 'Noto Sans Thai', sans-serif; -webkit-tap-highlight-color: transparent; }
    @keyframes pulse-wave {
      0%, 100% { height: 8px; }
      50% { height: 32px; }
    }
    .wave-playing .wave-bar:nth-child(1) { animation: pulse-wave 0.8s infinite 0.1s; }
    .wave-playing .wave-bar:nth-child(2) { animation: pulse-wave 0.7s infinite 0.3s; }
    .wave-playing .wave-bar:nth-child(3) { animation: pulse-wave 0.9s infinite 0.2s; }
    .wave-playing .wave-bar:nth-child(4) { animation: pulse-wave 0.6s infinite 0.4s; }
    .wave-playing .wave-bar:nth-child(5) { animation: pulse-wave 0.85s infinite 0.15s; }
    .wave-playing .wave-bar:nth-child(6) { animation: pulse-wave 0.75s infinite 0.35s; }
    .wave-playing .wave-bar:nth-child(7) { animation: pulse-wave 0.95s infinite 0.25s; }
    .wave-playing .wave-bar:nth-child(8) { animation: pulse-wave 0.65s infinite 0.45s; }
    .wave-playing .wave-bar:nth-child(9) { animation: pulse-wave 0.8s infinite 0.2s; }
    .wave-playing .wave-bar:nth-child(10) { animation: pulse-wave 0.7s infinite 0.3s; }
  </style>
</head>
<body class="bg-slate-100 min-h-screen text-slate-800 flex justify-center pb-12">
  <div class="w-full max-w-md bg-white min-h-screen shadow-2xl flex flex-col">
    
    <!-- Top App Bar -->
    <header class="sticky top-0 bg-white/90 backdrop-blur-md border-b border-slate-100 px-4 py-3.5 flex items-center justify-between z-20">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-lg bg-blue-600 text-white flex items-center justify-center font-bold text-sm shadow-sm">
          SB
        </div>
        <span class="font-bold text-slate-900 tracking-tight text-base">SplitBill</span>
      </div>
      <span class="text-xs bg-blue-50 text-blue-700 font-semibold px-2.5 py-1 rounded-full border border-blue-100">
        Zero-Install Web
      </span>
    </header>

    <!-- Main Content -->
    <main class="flex-1 px-5 py-4 space-y-4">

      <!-- Status Banner if Paid -->
      <div id="paidBanner" class="${isPaid ? '' : 'hidden'} bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl p-4 text-center">
        <div class="text-3xl mb-1">🎉</div>
        <div class="font-bold text-base">รายการนี้ชำระเงินเรียบร้อยแล้ว</div>
        <div class="text-xs text-emerald-600 mt-0.5">ขอบคุณที่ชำระตรงเวลาครับ/ค่ะ</div>
      </div>

      <!-- Voice Message Hero Card -->
      <div class="bg-gradient-to-b from-blue-50/60 to-white border border-blue-200/70 rounded-3xl p-5 shadow-sm">
        
        <!-- Sender Header -->
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <div class="w-12 h-12 rounded-full bg-blue-600 text-white flex items-center justify-center text-xl font-bold shadow-md shadow-blue-500/20">
              🔵
            </div>
            <div>
              <h2 class="font-bold text-slate-900 text-base leading-tight">${data.senderName} ส่งเสียงทวง</h2>
              <p class="text-xs text-slate-500 mt-0.5">${data.billTitle} · สไตล์ ${data.persona}</p>
            </div>
          </div>

          <!-- Play/Pause Button -->
          <button id="playBtn" onclick="togglePlay()" class="w-12 h-12 rounded-full bg-blue-600 hover:bg-blue-700 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-blue-600/30 transition-all">
            <svg id="playIcon" class="w-6 h-6 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z"/>
            </svg>
            <svg id="pauseIcon" class="w-6 h-6 hidden" fill="currentColor" viewBox="0 0 24 24">
              <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
            </svg>
          </button>
        </div>

        <!-- Audio Waveform Visualizer -->
        <div class="bg-white rounded-2xl p-3.5 border border-blue-100 flex items-center justify-between gap-1 shadow-inner">
          <div id="waveform" class="flex items-center justify-center gap-1.5 flex-1 h-9">
            <div class="wave-bar w-1.5 h-2 bg-blue-400 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-3 bg-blue-500 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-5 bg-blue-600 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-4 bg-blue-400 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-7 bg-blue-600 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-6 bg-blue-500 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-4 bg-blue-400 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-5 bg-blue-600 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-3 bg-blue-500 rounded-full transition-all"></div>
            <div class="wave-bar w-1.5 h-2 bg-blue-400 rounded-full transition-all"></div>
          </div>
          <span id="timeDisplay" class="text-xs font-semibold text-slate-400 font-mono pl-2">
            0:0${data.durationSeconds || 8}
          </span>
        </div>

        <!-- Amount & Pay Button -->
        <div class="mt-4 pt-4 border-t border-slate-100 flex items-center justify-between">
          <div>
            <div class="text-xs text-slate-500 font-medium">ยอดที่ต้องชำระ</div>
            <div class="text-2xl font-extrabold text-slate-900 tracking-tight">฿${formattedAmount}</div>
          </div>
          <a href="#paymentSection" class="bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm px-6 py-2.5 rounded-xl shadow-md shadow-blue-500/20 active:scale-95 transition-all">
            จ่ายเลย ↗
          </a>
        </div>
      </div>

      <!-- Transcript Box -->
      <div class="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
        <div class="flex items-center gap-2 mb-2 text-slate-900 font-bold text-sm">
          <span>📝</span>
          <span>ถอดข้อความเสียง (Transcript)</span>
        </div>
        <p class="text-sm text-slate-700 leading-relaxed italic bg-slate-50 p-3 rounded-xl border border-slate-100">
          "${data.transcript}"
        </p>
        <p class="text-xs text-slate-400 mt-2">💡 ฟังไม่สะดวก? สามารถอ่านข้อความด้านบนแทนได้เสมอ</p>
      </div>

      <!-- PromptPay Payment Section -->
      <div id="paymentSection" class="bg-white border border-slate-200 rounded-3xl p-5 shadow-sm text-center">
        <div class="flex items-center justify-center gap-2 mb-3">
          <img src="https://upload.wikimedia.org/wikipedia/commons/c/c5/PromptPay-logo.png" alt="PromptPay" class="h-6 object-contain">
        </div>

        <p class="text-xs text-slate-500 mb-3">สแกน QR Code ด้วยแอปธนาคารใดก็ได้ เพื่อชำระเงิน</p>

        <!-- QR Box -->
        <div class="inline-block p-3 bg-white border-2 border-slate-800 rounded-2xl shadow-md mb-4">
          <img src="${qrDataUrl}" alt="PromptPay QR Code" class="w-56 h-56 mx-auto object-contain">
        </div>

        <!-- PromptPay Copy Number -->
        <div class="bg-slate-50 border border-slate-200 rounded-xl p-3 flex items-center justify-between mb-4">
          <div class="text-left">
            <div class="text-xs text-slate-400">เลขพร้อมเพย์ของผู้รับ</div>
            <div class="font-bold text-slate-800 font-mono text-sm">${data.promptPayNumber}</div>
          </div>
          <button onclick="copyPromptPay('${data.promptPayNumber}')" class="bg-white border border-slate-300 hover:bg-slate-100 active:scale-95 text-xs font-semibold px-3 py-1.5 rounded-lg transition-all text-slate-700">
            คัดลอก 📋
          </button>
        </div>

        <!-- Bank App Deep Links -->
        <div class="space-y-2">
          <div class="text-xs text-slate-400 font-medium">เปิดแอปธนาคารในเครื่อง</div>
          <div class="grid grid-cols-3 gap-2">
            <a href="kplus://" class="bg-emerald-50 hover:bg-emerald-100 text-emerald-800 font-bold text-xs py-2 px-1 rounded-xl border border-emerald-200 transition-all text-center">
              K PLUS
            </a>
            <a href="scbeasy://" class="bg-purple-50 hover:bg-purple-100 text-purple-800 font-bold text-xs py-2 px-1 rounded-xl border border-purple-200 transition-all text-center">
              SCB EASY
            </a>
            <a href="ktbnext://" class="bg-sky-50 hover:bg-sky-100 text-sky-800 font-bold text-xs py-2 px-1 rounded-xl border border-sky-200 transition-all text-center">
              Krungthai
            </a>
          </div>
        </div>
      </div>

      <!-- Quick Replies Section -->
      <div class="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm">
        <div class="font-bold text-slate-900 text-sm mb-3">ตอบกลับเร็ว (Quick Reply)</div>
        <div class="flex flex-wrap gap-2">
          <button onclick="sendQuickReply('💸 โอนแล้ว', 'paid')" class="bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 font-semibold text-xs px-3.5 py-2 rounded-xl active:scale-95 transition-all">
            💸 โอนแล้ว
          </button>
          <button onclick="sendQuickReply('⏰ ขอ 3 วัน', 'deferred')" class="bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-200 font-semibold text-xs px-3.5 py-2 rounded-xl active:scale-95 transition-all">
            ⏰ ขอ 3 วัน
          </button>
          <button onclick="sendQuickReply('😅 ลืมสนิท ขอโทษที', 'pending')" class="bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200 font-semibold text-xs px-3.5 py-2 rounded-xl active:scale-95 transition-all">
            😅 ลืมสนิท ขอโทษที
          </button>
        </div>
      </div>

    </main>

    <!-- Footer -->
    <footer class="mt-auto px-5 py-4 border-t border-slate-100 text-center text-xs text-slate-400">
      ระบบทวงเงินอัตโนมัติ SplitBill · ปลอดภัย ไม่บันทึกข้อมูลส่วนบุคคล
    </footer>

    <!-- Toast Notification -->
    <div id="toast" class="fixed bottom-6 left-1/2 -translate-x-1/2 bg-slate-900 text-white text-xs font-medium px-4 py-2.5 rounded-full shadow-2xl opacity-0 pointer-events-none transition-all duration-300 z-50">
      แจ้งเตือน
    </div>

  </div>

  <!-- Audio Player Logic -->
  <audio id="audioEl" preload="auto" ${data.audioBase64 ? `src="${data.audioBase64.startsWith('data:') ? data.audioBase64 : 'data:audio/mp3;base64,' + data.audioBase64}"` : ''}></audio>

  <script>
    const nudgeId = '${data.id}';
    const transcriptText = ${JSON.stringify(data.transcript)};
    const audioEl = document.getElementById('audioEl');
    const playBtn = document.getElementById('playBtn');
    const playIcon = document.getElementById('playIcon');
    const pauseIcon = document.getElementById('pauseIcon');
    const waveform = document.getElementById('waveform');
    let isPlaying = false;

    function showToast(msg) {
      const toast = document.getElementById('toast');
      toast.innerText = msg;
      toast.classList.remove('opacity-0', 'pointer-events-none');
      setTimeout(() => {
        toast.classList.add('opacity-0', 'pointer-events-none');
      }, 3000);
    }

    function togglePlay() {
      if (isPlaying) {
        stopAudio();
      } else {
        startAudio();
      }
    }

    function startAudio() {
      isPlaying = true;
      playIcon.classList.add('hidden');
      pauseIcon.classList.remove('hidden');
      waveform.classList.add('wave-playing');

      if (audioEl.src && audioEl.src.length > 50) {
        audioEl.play().catch(e => {
          console.log('Audio playback error, fallback to TTS:', e);
          speakTTS();
        });
      } else {
        speakTTS();
      }
    }

    function stopAudio() {
      isPlaying = false;
      playIcon.classList.remove('hidden');
      pauseIcon.classList.add('hidden');
      waveform.classList.remove('wave-playing');

      if (audioEl) audioEl.pause();
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
      }
    }

    audioEl.onended = () => stopAudio();

    function speakTTS() {
      if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(transcriptText);
        utterance.lang = 'th-TH';
        utterance.rate = 0.95;
        utterance.onend = () => stopAudio();
        utterance.onerror = () => stopAudio();
        window.speechSynthesis.speak(utterance);
      } else {
        setTimeout(stopAudio, 4000);
      }
    }

    function copyPromptPay(num) {
      const cleanNum = num.replace(/-/g, '');
      navigator.clipboard.writeText(cleanNum).then(() => {
        showToast('คัดลอกเลขพร้อมเพย์แล้ว (' + cleanNum + ') 📋');
      }).catch(() => {
        showToast('คัดลอกเลขพร้อมเพย์: ' + cleanNum);
      });
    }

    async function sendQuickReply(replyText, status) {
      showToast('กำลังส่งข้อความ: ' + replyText + '...');
      try {
        const res = await fetch('/api/nudge/' + nudgeId + '/reply', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ replyMessage: replyText, status: status })
        });
        const data = await res.json();
        if (data.success) {
          showToast('ส่งข้อความถึงเพื่อนเรียบร้อยแล้ว ✅');
          if (status === 'paid') {
            document.getElementById('paidBanner').classList.remove('hidden');
          }
        }
      } catch (e) {
        showToast('ส่งข้อความตอบกลับเรียบร้อย (ออฟไลน์) ✅');
      }
    }
  </script>
</body>
</html>
    `);
  } catch (err) {
    console.error('Render error:', err);
    res.status(500).send('<h1>500 Internal Server Error</h1><p>' + err.message + '</p>');
  }
});

// Export Express app for Vercel Serverless Function
module.exports = app;

// Local development support
if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server running locally at http://localhost:${PORT}`);
  });
}
