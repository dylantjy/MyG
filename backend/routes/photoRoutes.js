const express = require('express');
const multer = require('multer');
const { getOpenAI, model } = require('../utils/openai');
const router = express.Router();

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

// Takes a food photo (field "image") plus an optional text "description", returns estimated macros
router.post('/photo-macros', upload.single('image'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No image uploaded' });

  const description = (req.body.description || '').trim();
  const imageUrl = `data:${req.file.mimetype || 'image/jpeg'};base64,${req.file.buffer.toString('base64')}`;

  const prompt = `Identify the food in this photo and estimate the macros for the portion shown, as eaten in Singapore.${description ? ` The user describes it as: "${description}".` : ''}
If it is a real, edible food, return JSON: {"dish": string, "calories": number, "protein": number, "carbs": number, "fat": number}.
Protein, carbs and fat are in grams, and calories must equal 4*protein + 4*carbs + 9*fat.
If the photo does not show edible food, return JSON: {"error": "Not an edible food"}.`;

  try {
    const aiResponse = await getOpenAI().chat.completions.create({
      model,
      messages: [
        { role: "system", content: "You are a nutrition assistant. Respond only in JSON." },
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: imageUrl } }
          ]
        }
      ],
      response_format: { type: "json_object" },
      temperature: 0.3
    });

    res.json(JSON.parse(aiResponse.choices[0].message.content));
  } catch (err) {
    console.error("Error in photo-macros:", err.message);
    res.status(500).json({ error: "Unable to analyze image", detail: err.message });
  }
});

module.exports = router;
