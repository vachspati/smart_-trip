# Smart Trip Planner - Architecture Documentation

## Overview

This Flutter application follows Clean Architecture principles with a clear separation of concerns across three main layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│  • Pages (ChatPage, HomePage, TripDetailPage)                  │
│  • Widgets (ItineraryView, DemoDebugOverlay)                   │
│  • State Management (Riverpod)                                 │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DOMAIN LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  • Entities (TripEntity, TripDayEntity, TripItemEntity)       │
│  • Use Cases (GenerateItineraryUseCase, SaveTripUseCase)      │
│  • Repository Interfaces                                       │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                          DATA LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│  • Models (Trip, TripDay, TripItem with JSON serialization)   │
│  • Repositories (TripRepository)                              │
│  • Data Sources (AgentApi, LocalDb)                           │
│  • Local Storage (SQLite via sqflite)                         │
└─────────────────────────────────────────────────────────────────┘
```

## Backend Integration Flow

```
┌─────────────────┐    HTTP/SSE    ┌─────────────────┐
│  Flutter App    │ ────────────► │  Backend API    │
│                 │               │  (Node.js)      │
│  • Chat UI      │               │                 │
│  • Token Stream │               │  • Express      │
│  • Error Handle │               │  • OpenAI API   │
└─────────────────┘               │  • Tool Chain   │
         │                        └─────────────────┘
         │                                  │
         ▼                                  ▼
┌─────────────────┐               ┌─────────────────┐
│  Local Storage  │               │   External APIs │
│                 │               │                 │
│  • SQLite DB    │               │  • OpenAI GPT   │
│  • Cached Trips │               │  • Bing Search  │
│  • Offline Mode │               │  • SerpAPI      │
└─────────────────┘               └─────────────────┘
```

## Agent Chain Architecture

```
User Prompt → Backend API → LLM Processing → Tool Calling → Validated JSON → Flutter Client

1. User Input:
   ┌─────────────────┐
   │ "5 days in Kyoto│
   │ solo, mid-range"│
   └─────────────────┘
            │
            ▼
2. Backend Processing:
   ┌─────────────────┐
   │ • Prompt Parse  │
   │ • Context Build │
   │ • LLM Request   │
   └─────────────────┘
            │
            ▼
3. LLM Response:
   ┌─────────────────┐
   │ • Token Stream  │
   │ • Tool Calls    │
   │ • JSON Output   │
   └─────────────────┘
            │
            ▼
4. Flutter Processing:
   ┌─────────────────┐
   │ • Parse JSON    │
   │ • Update UI     │
   │ • Save to DB    │
   └─────────────────┘
```

## Key Components

### 1. Backend API Client (`BackendApiClient`)
- Handles HTTP communication with backend
- Manages streaming responses (SSE)
- Implements retry logic and error handling
- Monitors connectivity status

### 2. Agent API (`AgentApi`)
- Abstraction layer for backend communication
- Handles itinerary generation requests
- Manages health checks and online status

### 3. Trip Repository (`TripRepository`)
- Coordinates between API and local storage
- Implements offline-first approach
- Handles error scenarios gracefully

### 4. Maps Integration (`MapsIntegration`)
- Launches Google Maps for locations
- Handles coordinate parsing
- Provides directions and search functionality

### 5. Local Database (`LocalDb`)
- SQLite-based storage using sqflite
- Stores trip data with JSON serialization
- Enables offline access to saved trips

## Data Flow

### Generation Flow:
```
1. User enters prompt in ChatPage
2. TripRepository checks backend availability
3. If online: AgentApi streams response
4. Tokens displayed in real-time
5. Complete itinerary parsed and shown
6. User can save to local database
7. Metrics displayed for token usage
```

### Offline Flow:
```
1. App detects no connectivity
2. Shows appropriate error message
3. Loads cached trips from LocalDb
4. User can view saved itineraries
5. Maps integration works with cached data
```

## Error Handling Strategy

### Network Errors:
- SocketException → "Network connection failed"
- TimeoutException → "Request timed out"
- HTTP 401 → "Unauthorized access"
- HTTP 429 → "Rate limit exceeded"
- HTTP 500+ → "Server error occurred"

### Graceful Degradation:
1. **No Internet**: Show cached trips only
2. **Backend Down**: Display health status
3. **Partial Failure**: Continue with available data
4. **Token Errors**: Retry with exponential backoff

## Testing Strategy

### Unit Tests:
- `BackendApiClient`: HTTP handling, error scenarios
- `TripRepository`: Business logic, offline handling
- `MapsIntegration`: Coordinate parsing, URL generation

### Widget Tests:
- `ChatPage`: UI interactions, error messages
- `ItineraryView`: Trip display, maps integration
- `DemoDebugOverlay`: Debug information display

### Integration Tests:
- End-to-end trip generation flow
- Offline/online mode switching
- Error recovery scenarios

## Performance Considerations

### Token Streaming:
- Real-time UI updates during generation
- Efficient string concatenation
- Smooth scrolling animations

### Local Storage:
- JSON serialization for complex data
- Efficient SQLite queries
- Lazy loading for large datasets

### Memory Management:
- Proper disposal of HTTP clients
- Stream subscription cleanup
- Widget lifecycle management

## Security Considerations

### API Keys:
- Environment variables for sensitive data
- No hardcoded secrets in source code
- Secure storage recommendations

### Data Privacy:
- Local storage only for trip data
- No personal data sent to backend
- User consent for external map services

## Deployment Architecture

### Development:
```
Flutter App ──→ localhost:8080 ──→ Local Backend ──→ OpenAI API
```

### Production:
```
Flutter App ──→ Your Domain ──→ Cloud Functions ──→ OpenAI API
            └──→ Google Play/App Store
```

This architecture ensures scalability, maintainability, and a great user experience both online and offline.
