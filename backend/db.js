const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

let memoryServer;

// Connects to MONGODB_URI if set; otherwise runs a local MongoDB that persists to backend/.data
async function connectDatabase() {
    if (process.env.MONGODB_URI) {
        await mongoose.connect(process.env.MONGODB_URI);
        return 'MongoDB at MONGODB_URI';
    }
    const { MongoMemoryServer } = require('mongodb-memory-server');
    const dbPath = path.join(__dirname, '.data');
    fs.mkdirSync(dbPath, { recursive: true });
    memoryServer = await MongoMemoryServer.create({
        instance: { dbPath, storageEngine: 'wiredTiger' }
    });
    await mongoose.connect(memoryServer.getUri('myg'));
    return `local MongoDB (data in ${dbPath})`;
}

// Shuts the local MongoDB down cleanly so recent writes are flushed to disk and the data is kept
async function disconnectDatabase() {
    await mongoose.disconnect();
    if (memoryServer) {
        await memoryServer.stop({ doCleanup: false });
        memoryServer = undefined;
    }
}

function isLocalDatabase() {
    return !process.env.MONGODB_URI;
}

module.exports = { connectDatabase, disconnectDatabase, isLocalDatabase };
