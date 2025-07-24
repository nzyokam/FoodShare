# 🌍 FoodShare Kenya - Connecting Surplus Food with Those in Need

**PROJECT BY MUUSI NGUUTU NZYOKA**

[LIVE SITE](https://fooddsharee.netlify.app/)

A Flutter-powered mobile application designed to combat hunger and food waste in Kenya by connecting restaurants with surplus food to shelters and community organizations in need.

## 📱 Project Overview

- **Status**: Active Development (Core Features Implemented)
- **Type**: Individual Project 
- **Platform**: Flutter (built using iOS simulator primarily for iOS, may have issues on Android devices)
- **Target Region**: Kenya (Nairobi, Mombasa, Nakuru, Eldoret, Kisumu)
- **Purpose**: Social Impact Application

## 🎯 Mission Statement

To fight hunger in Kenya by creating a direct bridge between restaurants with surplus food and shelters that need it most, while reducing food waste and building stronger communities through accessible technology.

## 👥 Current User Roles

### 🍽️ Restaurants (Food Donors)
- Post surplus food donations with photos and details
- Manage donation listings (edit, pause, cancel)
- Accept or decline requests from shelters
- Track donation history and impact
- Chat with shelters for coordination

### 🏠 Shelters (Food Recipients) 
- Browse available food donations by location and category
- Request specific donations with personalized messages
- Filter by food type, location, and expiry time
- Track request status (pending, approved, declined)
- Chat with restaurants for pickup coordination

## ✨ Implemented Features

### 🍲 For Restaurants
- **Donation Management**
  - Create food listings with photos, quantities, and descriptions
  - Set pickup times and expiry dates
  - Categorize food (fruits, vegetables, meat, dairy, prepared meals, etc.)
  - Location-based posting with city selection
  - Real-time status tracking (available, reserved, completed, cancelled)

- **Request Handling**
  - Receive and review requests from shelters
  - Accept or decline requests with optional messages
  - View shelter information and request messages
  - Automatic donation status updates when approved

- **Communication**
  - In-app chat system with shelters
  - Real-time messaging for coordination
  - Chat available for reserved and completed donations

### 🏠 For Shelters
- **Food Discovery**
  - Browse donations with search and filter capabilities
  - Filter by city, food category, and keywords
  - View expiry times with urgent notifications
  - See restaurant details and donation descriptions

- **Request System**
  - Send personalized request messages to restaurants
  - Track request status across three tabs (pending, approved, declined)
  - Prevent duplicate requests for same donation
  - View complete request history

- **Communication**
  - Chat with restaurants for pickup details
  - Real-time messaging system
  - Access to approved donation conversations

### 🔐 Authentication & User Management
- Secure user registration and login
- Role-based access (restaurant vs shelter)
- User profile management
- Business verification for restaurants

### 📱 User Interface
- Clean, intuitive design optimized for Kenyan users
- Tabbed navigation for easy access to features
- Real-time updates across all screens
- Mobile-first responsive design
- Kenyan city integration (Nairobi, Mombasa, Nakuru, etc.)

## 🛠️ Technical Implementation

### **Current Tech Stack**
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore (NoSQL Database)
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage (for food images)
- **Real-time Updates**: Firestore real-time listeners
- **State Management**: StatefulWidget with Streams

### **Database Collections**
- `restaurants` - Restaurant profile information
- `shelters` - Shelter profile information  
- `donations` - Food donation listings
- `requests` - Shelter requests for donations
- `chats` - Real-time messaging between users

### **Key Features Implemented**
- Real-time data synchronization
- Image upload and display
- Location-based filtering
- Status-based workflows
- Chat messaging system
- Request management
- Multi-user role system

## 📊 Current Functionality Status

### ✅ Completed Features
- User authentication (restaurants & shelters)
- Food donation creation and management
- Image upload for food items
- Location and category filtering
- Request system between shelters and restaurants
- Real-time chat messaging
- Donation status management
- Request status tracking
- Multi-tab organization
- Search functionality

### 🚧 In Development
- Firebase composite index optimization
- Performance improvements
- Bug fixes and refinements
- User experience enhancements

### 📋 Planned Features
- Push notifications for new donations and requests
- Impact tracking (meals saved, CO₂ offset)
- Admin dashboard for monitoring
- SMS integration for basic phone users
- Volunteer delivery coordination
- Food safety guidelines and checklists
- Multi-language support (English/Swahili)
- Analytics and reporting

## 🗺️ Current User Flows

### Restaurant Flow
1. Register as restaurant → Create profile
2. Post food donation with photos and details
3. Receive requests from shelters
4. Accept/decline requests
5. Chat with shelters for pickup coordination
6. Mark donations as completed
7. View donation history and impact

### Shelter Flow  
1. Register as shelter → Create profile
2. Browse available donations by location/category
3. Send requests with personalized messages
4. Track request status (pending/approved/declined)
5. Chat with restaurants for approved donations
6. Coordinate pickup details
7. View request history

## 📍 Geographic Focus

**Primary Cities Supported:**
- Nairobi
- Mombasa  
- Nakuru
- Eldoret
- Kisumu
- Other (expandable)

The app is designed specifically for the Kenyan market with local city integration and culturally appropriate design patterns.

## 🚀 Development Progress

### Phase 1: Core MVP ✅
- [x] User authentication system
- [x] Basic food listing and claiming
- [x] Restaurant and shelter profiles
- [x] Request management system
- [x] Real-time chat functionality

### Phase 2: Enhanced Experience (Current)
- [x] Advanced filtering and search
- [x] Image management
- [x] Status tracking workflows
- [ ] Performance optimization
- [ ] Database indexing completion
- [ ] UI/UX refinements

### Phase 3: Scale & Impact (Next)
- [ ] Push notification system
- [ ] Impact tracking dashboard
- [ ] Admin monitoring tools
- [ ] SMS integration for accessibility
- [ ] Volunteer delivery network
- [ ] Food safety features

## 💽 Database Optimization

Currently implementing Firebase Firestore composite indexes for:
- Donation queries with multiple filters
- Request status tracking
- Real-time chat performance
- Location-based filtering

## 🌐 Social Impact Goals

### Immediate Impact
- Connect surplus restaurant food with shelters in major Kenyan cities
- Reduce food waste in urban areas
- Provide reliable food access for vulnerable populations
- Build networks between restaurants and aid organizations

### Long-term Vision
- Expand to rural areas and smaller cities
- Integrate volunteer delivery networks
- Add food safety and handling education
- Create comprehensive impact measurement
- Build sustainable food rescue ecosystem in Kenya

## 📈 Success Metrics (Planned)

- Number of meals rescued from waste
- Active restaurant and shelter partnerships
- Request fulfillment rates
- User engagement and retention
- Geographic expansion success
- Community impact stories

## 🤝 Community Focus

This application addresses real challenges in Kenya:
- High food waste in restaurants
- Food insecurity in urban areas
- Limited coordination between food donors and recipients
- Need for accessible technology solutions
- Building community partnerships

## 📞 Contact & Development

**Developer**: Muusi Nguutu Nzyoka  
**Email**: muusi@nzyoka.com  
**Project Type**: Individual Social Impact Initiative  
**Focus**: Practical solutions for hunger and food waste in Kenya

---

*"Technology can bridge the gap between surplus and need. Every meal saved is a step toward a more food-secure Kenya."*