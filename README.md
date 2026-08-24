# PalDari

Global community platform with real-time translation chat.

PalDari is a web/mobile application designed to help users communicate
across language barriers through real-time translated conversations.

## Key Features

- Real-time chat using WebSocket/STOMP
- External translation API integration for real-time translated messages
- JWT-based authentication and authorization
- Google OAuth2 login
- Email verification
- Community features
- User profile management

## Tech Stack

### Backend
- Java
- Spring Boot
- Spring Security
- Spring Data JPA
- WebSocket / STOMP

### Database
- MySQL

### Client
- Flutter

### Authentication
- JWT (Access Token / Refresh Token)
- Google OAuth2
- Email Verification

## Project Structure

PalDari/
├── PalDari_Backend/     # Spring Boot backend server
└── PalDari_Frontend/    # Flutter application

## My Contributions

I primarily focused on backend development in a two-person team.

- Designed and implemented REST APIs using Spring Boot
- Implemented JWT-based authentication and authorization
- Implemented Google OAuth2 authentication
- Implemented email verification
- Developed real-time chat using WebSocket/STOMP
- Designed backend entities and database structure using JPA and MySQL
- Integrated the external translation API into the chat service
- Connected backend APIs with the Flutter client

## Related Research

The real-time translation feature developed in this project later served as the basis for a separate performance optimization study on reducing repeated external API calls.

The follow-up study evaluated Redis-based caching and was developed into the manuscript:

**“A Study on External API Call Optimization and Performance Improvement through Redis Caching in a Real-Time Translation Chat Service”**

## Team

2 developers
