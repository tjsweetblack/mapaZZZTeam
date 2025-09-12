require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } = require('@google/generative-ai');
const { createServer } = require('vercel-express');

const app = express();

app.use(cors());
app.use(express.json());

// Debug: Log when server starts
console.log('Starting Malaria Gemini API...');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const promptTemplate = (symptomsDescription) => `
Você é um especialista em saúde.  
Considere a seguinte lista de sintomas comuns da malária: 
- Febre  
- Calafrios  
- Suor excessivo  
- Dor de cabeça  
- Náusea  
- Vômito  
- Dor muscular  
- Fadiga intensa  

Com base na descrição dos sintomas fornecida: "${symptomsDescription}", faça o seguinte: 
1. valide se é um sintoma real ou não, caso não for um sintoma real descarte
2. Verifique quantos dos sintomas acima aparecem na descrição.  
3. Calcule a porcentagem: (número de sintomas presentes ÷ número total de sintomas na lista) × 100.  
4. Responda apenas com o número da porcentagem (ex: "62%") seguido de uma explicação muito breve em português (1 ou 2 frases) dizendo que essa porcentagem se deve à quantidade de sintomas compatíveis com malária.  
5. Não mencione nenhuma doença além da malária.
6. Se nenhum sintoma da lista estiver presente, responda "0%" e uma explicação breve dizendo que não há sintomas compatíveis com malária.
`;

app.post('/malaria-probability', async (req, res) => {
  const { symptomsDescription } = req.body;
  console.log('Received POST /malaria-probability');
  console.log('Request body:', req.body);
  if (!symptomsDescription) {
    console.log('symptomsDescription missing in request');
    return res.status(400).json({ error: 'symptomsDescription is required' });
  }

  try {
    const prompt = promptTemplate(symptomsDescription);
    console.log('Generated prompt:', prompt);
    const model = genAI.getGenerativeModel({ model: 'gemma-3n-e4b-it' });
    const result = await model.generateContent(prompt);
    const output = result.response.text().trim();
    console.log('Gemini API response:', output);

    // Parse percentage and explanation
    const regex = /(\d+(\.\d+)?)%\s*(.*)/;
    const match = output.match(regex);

    if (match) {
      const percentage = parseFloat(match[1]);
      const explanation = match[3]?.trim() || '';
      console.log('Parsed percentage:', percentage, 'Explanation:', explanation);
      res.json({
        percentage: Math.round(percentage),
        explanation: explanation || 'A explicação para esta probabilidade não foi fornecida.'
      });
    } else {
      console.log('Could not parse percentage/explanation from Gemini response');
      res.json({
        percentage: null,
        explanation: 'Não foi possível analisar a resposta para obter a probabilidade e explicação.'
      });
    }
  } catch (e) {
    console.error('Error in /malaria-probability:', e);
    res.status(500).json({ error: 'Erro ao obter a probabilidade: ' + e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Malaria Gemini API running on port ${PORT}`);
});

module.exports = createServer(app);
