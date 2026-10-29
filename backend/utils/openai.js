require('dotenv').config();
const { OpenAI } = require('openai');

// Without an OpenAI key, default to a free local model served by Ollama (https://ollama.com),
// which speaks the same API. The model must support JSON mode and image input.
const useOpenAI = Boolean(process.env.OPENAI_API_KEY);
const baseURL = process.env.OPENAI_BASE_URL || (useOpenAI ? undefined : 'http://localhost:11434/v1');
const model = process.env.OPENAI_MODEL || (useOpenAI ? 'gpt-4o-mini' : 'gemma3:4b');

// Created on first use so the server can still start (and serve non-AI routes) if the model isn't available
let client;
function getOpenAI() {
    if (!client) {
        client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY || 'ollama', baseURL });
    }
    return client;
}

module.exports = { getOpenAI, model, baseURL };
