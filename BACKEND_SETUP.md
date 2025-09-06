# Backend Setup Guide

This guide walks you through setting up the Node.js backend for the Smart Trip Planner Flutter app.

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- OpenAI API key

## 1. Backend Directory Structure

Create the following directory structure in your project root:

```
smart_trip_planner_flutter/
├── server/
│   └── functions/
│       ├── package.json
│       ├── .env.example
│       ├── .env
│       ├── index.js
│       └── src/
│           ├── agent.js
│           └── utils.js
└── lib/ (Flutter app)
```

## 2. Backend Setup

### Step 1: Create the package.json

```bash
mkdir -p server/functions
cd server/functions
```

Create `package.json`:

```json
{
  "name": "smart-trip-planner-backend",
  "version": "1.0.0",
  "description": "AI-powered trip planning backend",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "serve": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "openai": "^4.20.1",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

### Step 2: Install dependencies

```bash
npm install
```

### Step 3: Create environment file

Create `.env.example`:

```
# OpenAI Configuration
OPENAI_API_KEY=sk-your-openai-key-here

# Optional: Search APIs for enhanced location data
BING_SEARCH_KEY=your-bing-search-key
SERPAPI_KEY=your-serpapi-key

# Server Configuration
PORT=8080
NODE_ENV=development
```

Copy to `.env` and add your actual keys:

```bash
cp .env.example .env
# Edit .env with your actual API keys
```

### Step 4: Create the main server file

Create `index.js`:

```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.post('/generate-itinerary', async (req, res) => {
  try {
    const { prompt, previousItinerary, chatHistory } = req.body;
    
    // Set headers for Server-Sent Events
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // Import the agent module
    const { generateItinerary } = require('./src/agent');
    
    await generateItinerary({
      prompt,
      previousItinerary,
      chatHistory: chatHistory || [],
      onToken: (token) => {
        res.write(`data: ${JSON.stringify({ token })}\n\n`);
      },
      onJson: (itinerary) => {
        res.write(`data: ${JSON.stringify({ itinerary })}\n\n`);
      },
      onMetrics: (metrics) => {
        res.write(`data: ${JSON.stringify({ metrics })}\n\n`);
      },
      onComplete: () => {
        res.write(`data: [DONE]\n\n`);
        res.end();
      },
      onError: (error) => {
        res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
        res.end();
      }
    });
    
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`🚀 Smart Trip Planner Backend running on port ${port}`);
  console.log(`📍 Health check: http://localhost:${port}/health`);
  console.log(`🤖 Generate endpoint: http://localhost:${port}/generate-itinerary`);
});
```

### Step 5: Create the AI agent

Create `src/agent.js`:

```javascript
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const SYSTEM_PROMPT = `You are a travel planning expert. Create detailed, personalized itineraries in JSON format.

Response format:
{
  "title": "Trip name",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "days": [
    {
      "date": "YYYY-MM-DD",
      "summary": "Day overview",
      "items": [
        {
          "time": "HH:mm",
          "activity": "What to do",
          "location": "lat,lng"
        }
      ]
    }
  ]
}

Guidelines:
- Include realistic coordinates (lat,lng) for each location
- Suggest specific times for activities
- Consider travel time between locations
- Include diverse activities (sights, food, culture)
- Adapt to budget and travel style mentioned`;

async function generateItinerary({ 
  prompt, 
  previousItinerary, 
  chatHistory, 
  onToken, 
  onJson, 
  onMetrics, 
  onComplete, 
  onError 
}) {
  try {
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...chatHistory,
      { role: 'user', content: prompt }
    ];

    if (previousItinerary) {
      messages.push({
        role: 'assistant',
        content: `Previous itinerary: ${JSON.stringify(previousItinerary)}`
      });
    }

    const stream = await openai.chat.completions.create({
      model: 'gpt-4',
      messages,
      stream: true,
      temperature: 0.7,
      max_tokens: 2000,
    });

    let fullResponse = '';
    let promptTokens = 0;
    let completionTokens = 0;

    for await (const chunk of stream) {
      const delta = chunk.choices[0]?.delta;
      
      if (delta?.content) {
        const token = delta.content;
        fullResponse += token;
        onToken(token);
        completionTokens += 1;
      }

      if (chunk.usage) {
        promptTokens = chunk.usage.prompt_tokens;
        completionTokens = chunk.usage.completion_tokens;
      }
    }

    // Try to extract JSON from the response
    try {
      const jsonMatch = fullResponse.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const itinerary = JSON.parse(jsonMatch[0]);
        onJson(itinerary);
      }
    } catch (parseError) {
      console.error('JSON parse error:', parseError);
    }

    // Send metrics
    onMetrics({
      promptTokens: promptTokens || estimateTokens(messages),
      completionTokens: completionTokens || estimateTokens([{ content: fullResponse }]),
      totalTokens: (promptTokens || 0) + (completionTokens || 0)
    });

    onComplete();

  } catch (error) {
    console.error('Generation error:', error);
    onError(error);
  }
}

function estimateTokens(messages) {
  return messages.reduce((total, msg) => 
    total + Math.ceil((msg.content || '').length / 4), 0
  );
}

module.exports = { generateItinerary };
```

### Step 6: Create utilities (optional)

Create `src/utils.js`:

```javascript
// Utility functions for the backend

function validateItinerary(itinerary) {
  const required = ['title', 'startDate', 'endDate', 'days'];
  return required.every(field => itinerary[field]);
}

function sanitizeInput(input) {
  if (typeof input !== 'string') return '';
  return input.replace(/[<>]/g, '').trim();
}

module.exports = {
  validateItinerary,
  sanitizeInput
};
```

## 3. Running the Backend

### Development Mode

```bash
cd server/functions
npm run serve
```

The server will start on `http://localhost:8080`

### Production Mode

For production deployment, you can use services like:

- **Vercel**: Deploy with `vercel`
- **Netlify**: Deploy serverless functions
- **Google Cloud Functions**: Deploy to GCP
- **AWS Lambda**: Deploy to AWS

## 4. Testing the Backend

### Health Check

```bash
curl http://localhost:8080/health
```

### Generate Itinerary

```bash
curl -X POST http://localhost:8080/generate-itinerary \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "3 days in Paris, romantic trip, moderate budget",
    "chatHistory": []
  }'
```

## 5. Connecting to Flutter App

Update `lib/core/constants.dart` in your Flutter app:

```dart
class ApiConstants {
  static const String backendBaseUrl = 'http://localhost:8080'; // Development
  // static const String backendBaseUrl = 'https://your-domain.vercel.app'; // Production
}
```

For Android emulator, use:
```dart
static const String backendBaseUrl = 'http://10.0.2.2:8080';
```

## 6. Environment Variables

### Development
Set in `.env` file:

```
OPENAI_API_KEY=sk-your-key-here
PORT=8080
```

### Production
Set environment variables in your hosting platform:

- Vercel: Add in project settings
- Netlify: Add in site settings
- Cloud platforms: Use their respective env var systems

## 7. Security Considerations

- Never commit `.env` files
- Use HTTPS in production
- Implement rate limiting
- Add request validation
- Monitor API usage

## 8. Troubleshooting

### Common Issues

1. **Port already in use**: Change PORT in `.env`
2. **OpenAI API errors**: Check API key and quota
3. **CORS issues**: Verify CORS configuration
4. **JSON parsing**: Check response format

### Debugging

Enable debug logging:

```javascript
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});
```

## 9. Deployment Examples

### Vercel Deployment

1. Install Vercel CLI: `npm i -g vercel`
2. In `server/functions`: `vercel`
3. Set environment variables in Vercel dashboard
4. Update Flutter app with production URL

### Google Cloud Functions

1. Install gcloud CLI
2. Create `app.yaml` configuration
3. Deploy: `gcloud app deploy`
4. Update Flutter app with GCP URL

Your backend is now ready to power the Smart Trip Planner Flutter app! 🚀
