const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

// Connects to MONGODB_URI if set; otherwise runs a local MongoDB that persists to backend/.data
async function connectDatabase() {
    if (process.env.MONGODB_URI) {
        await mongoose.connect(process.env.MONGODB_URI);
        return 'MongoDB at MONGODB_URI';
    }
    const { MongoMemoryServer } = require('mongodb-memory-server');
    const dbPath = path.join(__dirname, '.data');
    fs.mkdirSync(dbPath, { recursive: true });
    const server = await MongoMemoryServer.create({
        instance: { dbPath, storageEngine: 'wiredTiger' }
    });
    await mongoose.connect(server.getUri('myg'));
    return `local MongoDB (data in ${dbPath})`;
}

module.exports = connectDatabase;
