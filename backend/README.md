# Smart Trip Planner Backend

A Node.js Express server that provides API endpoints for the Smart Trip Planner Flutter app.

## Features

- **Health Check**: Monitor server status
- **Itinerary Generation**: Create personalized travel plans with streaming responses
- **Destinations**: Get popular travel destinations
- **Travel Tips**: Helpful travel advice
- **CORS Enabled**: Works with Flutter app
- **Streaming Support**: Real-time response streaming

## Quick Start

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

3. For development with auto-restart:
```bash
npm run dev
```

The server will run on `http://localhost:8080`

## API Endpoints

### Health Check
- **GET** `/health` - Check server status

### Itinerary Generation
- **POST** `/generate-itinerary` - Generate travel itinerary
  - Body: `{ destination, duration, budget, interests }`
  - Returns: Streaming text response

### Destinations
- **GET** `/destinations` - Get popular destinations

### Travel Tips
- **GET** `/tips` - Get travel tips

## Environment Variables

Create a `.env` file:
```
PORT=8080
NODE_ENV=development
```

## Testing

Test health endpoint:
```bash
curl http://localhost:8080/health
```

Test itinerary generation:
```bash
curl -X POST http://localhost:8080/generate-itinerary \
  -H "Content-Type: application/json" \
  -d '{"destination":"Paris","duration":"3","budget":"1000","interests":["culture","food"]}'
```
