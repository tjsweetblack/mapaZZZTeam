require('dotenv').config();
const express = require('express');
const multer = require('multer');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

function requireSharedSecret(req, res, next) {
  const expected = process.env.REPORT_API_SHARED_SECRET;
  if (!expected || req.header('x-api-key') !== expected) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.post('/analyze-image', requireSharedSecret, upload.single('image'), async (req, res) => {
  console.log('Received POST /analyze-image');
  if (!req.file) {
    return res.status(400).json({ error: 'No image uploaded' });
  }
  try {
    const imageBytes = req.file.buffer;
    const prompt = `Analyze this image to detect potential mosquito breeding sites. Consider the presence of any of the following: 
- Stagnant water (puddles, pools, containers)
- Vegetation capable of holding water (e.g., dense grass, bromeliads)
- Discarded containers (tires, bottles, cans, flowerpots)
- Accumulated trash or debris
- Gutters or drainage systems
- Any other area where water may collect and remain for more than 4 days.
Respond with 'valid' if the image clearly shows one or more of these conditions, and 'invalid' if none are clearly present. Focus on the presence of standing water and items/areas that can hold water.`;

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

    // Correct way to format content for the Node.js SDK
    const content = [
      { text: prompt },
      { inlineData: { mimeType: req.file.mimetype, data: imageBytes.toString('base64') } }
    ];
    
    const result = await model.generateContent({ contents: [{ role: 'user', parts: content }] });
    const output = result.response.text().toLowerCase().trim();
    console.log('Gemini image analysis response:', output);

    res.json({ result: output });
  } catch (e) {
    console.error('Error in /analyze-image:', e);
    res.status(500).json({ error: 'Erro ao analisar a imagem: ' + e.message });
  }
});

const PORT = process.env.PORT || 3100;
app.listen(PORT, () => {
  console.log(`Malaria Gemini API running on port ${PORT}`);
});