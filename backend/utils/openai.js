require('dotenv').config();
const { OpenAI } = require('openai');

// Override with OPENAI_MODEL in .env; the default must support JSON mode and image input
const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';

// Created on first use so the server can still start (and serve non-AI routes) without a key
let client;
function getOpenAI() {
    if (!client) {
        client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    }
    return client;
}

module.exports = { getOpenAI, model };
