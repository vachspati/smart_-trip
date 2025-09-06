const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || 'demo-key');

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'Smart Trip Planner Backend',
    version: '1.0.0'
  });
});

// Generate itinerary endpoint with Gemini AI streaming support
app.post('/generate-itinerary', async (req, res) => {
  const { destination, duration, budget, interests, prompt } = req.body;

  // Set headers for streaming response
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');

  // Validate input - accept either destination or prompt
  const finalDestination = destination || prompt || 'Unknown Destination';
  
  if (!destination && !prompt) {
    res.status(400).json({ error: 'Destination or prompt is required' });
    return;
  }

  console.log(`Generating AI itinerary for: ${finalDestination}`);

  // Send streaming tokens
  const sendToken = (token) => {
    res.write(JSON.stringify({ token }) + '\n');
  };

  // Send final itinerary
  const sendItinerary = (itinerary) => {
    res.write(JSON.stringify({ itinerary }) + '\n');
  };

  // Send metrics
  const sendMetrics = (metrics) => {
    res.write(JSON.stringify({ metrics }) + '\n');
  };

  try {
    // Check if Gemini API key is available
    if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'demo-key') {
      console.log('Using demo mode - no Gemini API key provided');
      await generateDemoItinerary();
      return;
    }

    // Generate AI itinerary with Gemini
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });

    // Create detailed prompt for travel planning
    const aiPrompt = `Create a detailed travel itinerary for: ${finalDestination}
    
Duration: ${duration || '3'} days
Budget: $${budget || '1000'} per person
Interests: ${interests?.join(', ') || 'General sightseeing, culture, food'}

Please provide:
1. Day-by-day detailed itinerary with specific activities and timings
2. Recommended restaurants and local cuisines
3. Transportation tips
4. Budget breakdown
5. Cultural insights and local tips
6. Weather considerations
7. Packing suggestions

Format the response with clear headings, emojis, and helpful details. Make it engaging and practical.`;

    const result = await model.generateContentStream(aiPrompt);

    let fullText = '';
    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      fullText += chunkText;
      sendToken(chunkText);
    }

    // Create structured itinerary object
    const itinerary = {
      id: Date.now(),
      destination: finalDestination,
      duration: duration || '3',
      budget: budget || '1000',
      description: `AI-generated trip to ${finalDestination}`,
      fullText: fullText,
      days: extractDaysFromText(fullText),
      interests: interests || []
    };

    sendItinerary(itinerary);
    
    // Send completion metrics
    const metrics = {
      promptTokens: Math.floor(aiPrompt.length / 4), // Rough estimate
      completionTokens: Math.floor(fullText.length / 4),
      totalTokens: Math.floor((aiPrompt.length + fullText.length) / 4)
    };
    
    sendMetrics(metrics);
    res.end();

  } catch (error) {
    console.error('Gemini AI error:', error);
    console.log('Falling back to demo mode');
    await generateDemoItinerary();
  }

  // Fallback demo itinerary generator
  async function generateDemoItinerary() {
    const itineraryParts = [
      `🏝️ **Welcome to your ${finalDestination} adventure!**\n\n`,
      `📅 **${duration || '3'}-Day Itinerary for ${finalDestination}**\n\n`,
      `💰 **Budget**: $${budget || '1000'} per person\n\n`,
      
      `**Day 1: Arrival & City Exploration**\n`,
      `🌅 Morning: Arrive and check into your hotel\n`,
      `🏛️ Afternoon: Visit main landmarks and historic sites\n`,
      `🍽️ Evening: Try local cuisine at recommended restaurants\n`,
      `📍 Must-visit: City center, local markets\n\n`,
      
      `**Day 2: Cultural & Adventure Activities**\n`,
      `🎨 Morning: Museums and cultural attractions\n`,
      `🏞️ Afternoon: Outdoor activities and nature spots\n`,
      `🎭 Evening: Local entertainment and nightlife\n`,
      `📍 Highlights: ${interests?.join(', ') || 'Cultural sites, outdoor activities'}\n\n`,
      
      `**Day 3: Local Experiences & Departure**\n`,
      `🛍️ Morning: Shopping for local souvenirs\n`,
      `☕ Afternoon: Relax at local cafes and final sightseeing\n`,
      `✈️ Evening: Departure preparations\n\n`,
      
      `**📍 Key Locations:**\n`,
      `• Central Plaza, ${finalDestination}\n`,
      `• Historic District, ${finalDestination}\n`,
      `• Local Market Square, ${finalDestination}\n`,
      `• Scenic Viewpoint, ${finalDestination}\n\n`,
      
      `**💡 Pro Tips:**\n`,
      `• Book accommodations in advance\n`,
      `• Try local transportation options\n`,
      `• Don't forget travel insurance\n`,
      `• Learn basic local phrases\n\n`,
      
      `**📱 Useful Apps:**\n`,
      `• Google Maps for navigation\n`,
      `• Google Translate for communication\n`,
      `• Local weather app\n\n`,
      
      `Have an amazing trip to ${finalDestination}! 🎉`
    ];

    for (let i = 0; i < itineraryParts.length; i++) {
      sendToken(itineraryParts[i]);
      await new Promise(resolve => setTimeout(resolve, 200)); // Simulate streaming delay
    }

    // Send completion itinerary object
    const itinerary = {
      id: Date.now(),
      destination: finalDestination,
      duration: duration || '3',
      budget: budget || '1000',
      description: `A wonderful trip to ${finalDestination}`,
      days: [
        {
          day: 1,
          title: 'Arrival & City Exploration',
          activities: ['Check into hotel', 'Visit landmarks', 'Try local cuisine']
        },
        {
          day: 2,
          title: 'Cultural & Adventure Activities',
          activities: ['Museums', 'Outdoor activities', 'Local entertainment']
        },
        {
          day: 3,
          title: 'Local Experiences & Departure',
          activities: ['Shopping', 'Cafes', 'Departure preparations']
        }
      ]
    };
    
    sendItinerary(itinerary);
    
    // Send completion metrics
    const metrics = {
      promptTokens: 50,
      completionTokens: 300,
      totalTokens: 350
    };
    
    sendMetrics(metrics);
    res.end();
  }

  // Handle client disconnect
  req.on('close', () => {
    console.log('Client disconnected from itinerary generation');
  });
});

// Helper function to extract days from AI-generated text
function extractDaysFromText(text) {
  const days = [];
  const dayRegex = /\*\*Day (\d+)[:\s]*([^\n]*)\*\*/gi;
  let match;
  
  while ((match = dayRegex.exec(text)) !== null) {
    const dayNumber = parseInt(match[1]);
    const title = match[2].trim();
    
    // Extract activities for this day (simple heuristic)
    const dayStart = match.index;
    const nextDayMatch = dayRegex.exec(text);
    const dayEnd = nextDayMatch ? nextDayMatch.index : text.length;
    dayRegex.lastIndex = dayStart + match[0].length; // Reset for next iteration
    
    const dayContent = text.substring(dayStart, dayEnd);
    const activities = dayContent
      .split('\n')
      .filter(line => line.trim().match(/^[🌅🏛️🍽️🎨🏞️🎭🛍️☕✈️📍•-]/))
      .map(line => line.replace(/^[🌅🏛️🍽️🎨🏞️🎭🛍️☕✈️📍•-]\s*/, '').trim())
      .filter(activity => activity.length > 0);
    
    days.push({
      day: dayNumber,
      title: title,
      activities: activities.slice(0, 5) // Limit to 5 activities per day
    });
  }
  
  return days.length > 0 ? days : [
    { day: 1, title: 'Arrival & Exploration', activities: ['Check-in', 'City tour', 'Local dining'] },
    { day: 2, title: 'Adventure & Culture', activities: ['Museums', 'Activities', 'Entertainment'] },
    { day: 3, title: 'Relaxation & Departure', activities: ['Shopping', 'Cafes', 'Check-out'] }
  ];
}

// Get popular destinations
app.get('/destinations', (req, res) => {
  const destinations = [
    { id: 1, name: "Paris, France", description: "City of Love and Lights" },
    { id: 2, name: "Tokyo, Japan", description: "Modern metropolis with rich culture" },
    { id: 3, name: "New York, USA", description: "The Big Apple" },
    { id: 4, name: "London, England", description: "Historic and modern blend" },
    { id: 5, name: "Dubai, UAE", description: "Luxury and innovation" },
    { id: 6, name: "Rome, Italy", description: "Eternal City with ancient history" },
    { id: 7, name: "Bali, Indonesia", description: "Tropical paradise" },
    { id: 8, name: "Sydney, Australia", description: "Harbor city with iconic landmarks" }
  ];
  
  res.json(destinations);
});

// Get travel tips
app.get('/tips', (req, res) => {
  const tips = [
    "Book flights in advance for better deals",
    "Pack light and bring versatile clothing",
    "Research local customs and etiquette",
    "Keep digital and physical copies of important documents",
    "Notify your bank about travel plans",
    "Download offline maps and translation apps",
    "Pack a universal power adapter",
    "Consider travel insurance"
  ];
  
  res.json(tips);
});

// Search flights endpoint
app.post('/search-flights', (req, res) => {
  const { from, to, departDate, returnDate, passengers } = req.body;
  
  // Simulate flight search results
  const flights = [
    {
      id: 1,
      airline: "Emirates",
      from: from || "New York",
      to: to || "Dubai", 
      departTime: "08:00",
      arriveTime: "20:30",
      duration: "12h 30m",
      price: 850,
      stops: 0
    },
    {
      id: 2,
      airline: "British Airways",
      from: from || "New York",
      to: to || "Dubai",
      departTime: "14:15", 
      arriveTime: "09:45+1",
      duration: "15h 30m",
      price: 720,
      stops: 1
    },
    {
      id: 3,
      airline: "Qatar Airways",
      from: from || "New York", 
      to: to || "Dubai",
      departTime: "22:00",
      arriveTime: "18:20+1",
      duration: "14h 20m", 
      price: 890,
      stops: 1
    }
  ];
  
  res.json({ flights, searchParams: req.body });
});

// Search hotels endpoint
app.post('/search-hotels', (req, res) => {
  const { destination, checkIn, checkOut, guests, rooms } = req.body;
  
  // Simulate hotel search results
  const hotels = [
    {
      id: 1,
      name: "Grand Palace Hotel",
      location: destination || "Dubai",
      rating: 5,
      price: 250,
      currency: "USD",
      amenities: ["Wi-Fi", "Pool", "Gym", "Spa", "Restaurant"],
      image: "hotel1.jpg"
    },
    {
      id: 2,
      name: "City Center Inn",
      location: destination || "Dubai", 
      rating: 4,
      price: 120,
      currency: "USD",
      amenities: ["Wi-Fi", "Breakfast", "Gym"],
      image: "hotel2.jpg"
    },
    {
      id: 3,
      name: "Luxury Resort & Spa",
      location: destination || "Dubai",
      rating: 5,
      price: 380,
      currency: "USD", 
      amenities: ["Wi-Fi", "Pool", "Spa", "Beach Access", "All-Inclusive"],
      image: "hotel3.jpg"
    }
  ];
  
  res.json({ hotels, searchParams: req.body });
});

// Search car rentals endpoint
app.post('/search-cars', (req, res) => {
  const { location, pickupDate, returnDate, carType } = req.body;
  
  // Simulate car rental results
  const cars = [
    {
      id: 1,
      brand: "Toyota",
      model: "Camry",
      type: "Sedan",
      location: location || "Dubai Airport",
      pricePerDay: 45,
      currency: "USD",
      features: ["Automatic", "A/C", "GPS", "4 Doors", "5 Seats"],
      image: "car1.jpg"
    },
    {
      id: 2,
      brand: "Nissan", 
      model: "Altima",
      type: "SUV",
      location: location || "Dubai Airport",
      pricePerDay: 65,
      currency: "USD",
      features: ["Automatic", "A/C", "GPS", "4WD", "7 Seats"],
      image: "car2.jpg"
    },
    {
      id: 3,
      brand: "BMW",
      model: "3 Series", 
      type: "Luxury",
      location: location || "Dubai Airport",
      pricePerDay: 120,
      currency: "USD",
      features: ["Automatic", "A/C", "GPS", "Leather", "Premium Audio"],
      image: "car3.jpg"
    }
  ];
  
  res.json({ cars, searchParams: req.body });
});

// Search restaurants endpoint  
app.post('/search-restaurants', (req, res) => {
  const { location, cuisine, priceRange, date } = req.body;
  
  // Simulate restaurant search results
  const restaurants = [
    {
      id: 1,
      name: "The Golden Spoon",
      cuisine: cuisine || "International",
      location: location || "Dubai",
      rating: 4.8,
      priceRange: "$$$$",
      openHours: "6:00 PM - 11:00 PM",
      specialties: ["Seafood", "Steaks", "Fine Dining"],
      image: "restaurant1.jpg"
    },
    {
      id: 2,
      name: "Street Food Paradise", 
      cuisine: cuisine || "Local",
      location: location || "Dubai",
      rating: 4.5,
      priceRange: "$$",
      openHours: "11:00 AM - 10:00 PM", 
      specialties: ["Local Dishes", "Casual Dining", "Family Friendly"],
      image: "restaurant2.jpg"
    },
    {
      id: 3,
      name: "Rooftop Bistro",
      cuisine: cuisine || "Mediterranean", 
      location: location || "Dubai",
      rating: 4.7,
      priceRange: "$$$",
      openHours: "5:00 PM - 12:00 AM",
      specialties: ["Mediterranean", "City Views", "Cocktails"],
      image: "restaurant3.jpg"
    }
  ];
  
  res.json({ restaurants, searchParams: req.body });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: err.message 
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    path: req.originalUrl 
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Smart Trip Planner Backend running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`📱 Ready to serve Flutter app!`);
});

module.exports = app;
