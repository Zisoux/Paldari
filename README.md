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

As a backend-focused developer in a two-person team, I worked on:

- REST API design and implementation
- JWT-based authentication and authorization
- Google OAuth2 authentication
- Email verification
- WebSocket/STOMP-based real-time chat
- Backend database and entity design
- Integration between the Flutter application and Spring Boot backend

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
