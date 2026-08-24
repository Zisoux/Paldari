# PalDari

Global community platform with real-time translation chat.

PalDari is a web/mobile application designed to help users communicate
across language barriers through real-time translated conversations.

## Key Features

- Real-time chat using WebSocket/STOMP
- Real-time translation using an external Translation API
- JWT-based authentication
- Google OAuth2 login
- Email verification
- User matching and community features
- User profile and portfolio management

## Architecture

Frontend
- Flutter

Backend
- Java 21
- Spring Boot
- Spring Security
- Spring Data JPA
- WebSocket / STOMP

Database
- MySQL

Authentication
- JWT
- Google OAuth2

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

## Performance Optimization Research

While developing the real-time translation chat feature,
I identified repeated external translation API calls as a source of
unnecessary latency and API usage.

Based on this problem, I conducted a follow-up study applying
**Redis caching** to reuse previously translated results.

The performance evaluation considered:

- Response Time
- Throughput
- External API Call Count
- Cache Hit Ratio

This work was developed into the manuscript:

**“A Study on External API Call Optimization and Performance Improvement
through Redis Caching in a Real-Time Translation Chat Service”**

Accepted for publication following revision, 2026.

## Team

2 developers
