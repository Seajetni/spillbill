const dns = require('dns');
// Set custom DNS to ensure SRV records resolve reliably on all platforms
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  // Ignore in environments that don't permit custom DNS
}

const mongoose = require('mongoose');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://sea:S2UHiGtAAQiiRyDa@aquasmartguard.njwqyfu.mongodb.net/data?retryWrites=true&w=majority&appName=aquaSmartGuard';

/**
 * Global cache for Mongoose connection to survive Vercel serverless cold starts.
 */
let cached = global.mongoose;

if (!cached) {
  cached = global.mongoose = { conn: null, promise: null };
}

async function connectToDatabase() {
  if (cached.conn) {
    return cached.conn;
  }

  if (!cached.promise) {
    const opts = {
      bufferCommands: false,
      serverSelectionTimeoutMS: 8000,
    };

    cached.promise = mongoose.connect(MONGODB_URI, opts).then((m) => {
      console.log('MongoDB connected successfully to DB:', m.connection.name);
      return m;
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (e) {
    cached.promise = null;
    throw e;
  }

  return cached.conn;
}

module.exports = { connectToDatabase };
