# Project Context

## Project Overview

This is a **Telegram Bot** built with **Dart** using the **Televerse**
framework. The bot provides cryptocurrency price monitoring and alerting
functionality, specifically tracking price changes from the Bybit exchange API.

## Core Functionality

- **Price Monitoring**: Fetches cryptocurrency prices from Bybit API and monitors 24-hour percentage changes
- **User Subscriptions**: Allows users to subscribe/unsubscribe to price alerts via Telegram commands
- **Threshold Management**: Users can set custom price change thresholds for notifications
- **Real-time Alerts**: Sends notifications to subscribers when price changes exceed their threshold
- **Command Interface**: Full Telegram bot command system with menu integration

## Technical Architecture

### Framework & Dependencies

- **Dart SDK**: ^3.10.4
- **Televerse**: ^3.0.1 (Telegram Bot API framework)
- **HTTP**: ^1.6.0 (API requests)
- **DotEnv**: ^4.2.0 (Environment configuration)

### Project Structure

```
lib/
├── handlers/           # Bot command and conversation handlers
├── services/          # Business logic (price monitoring, bot state)
├── models/           # Data models (Bybit API responses)
└── constants.dart    # Application constants
```

### Key Components

- **Command Handlers**: Telegram bot commands (start, subscribe, unsubscribe, setthreshold, status)
- **Price Service**: Bybit API integration and price monitoring logic
- **Bot State**: Global state management for subscribers and configuration
- **Conversation System**: Interactive threshold setting via Televerse conversations
- **Data Models**: Type-safe JSON parsing for external API responses

## Code Quality Requirements

### Senior-Level Standards

The agent must write **senior-level, production-ready code** following these principles:

#### Architecture & Design

- **Clean Architecture**: Proper separation of concerns between handlers, services, and models
- **SOLID Principles**: Single responsibility, dependency injection, interface segregation
- **Error Handling**: Comprehensive error handling with proper logging and user feedback
- **Async/Await**: Proper asynchronous programming patterns for API calls and timers

#### Code Quality

- **Type Safety**: Leverage Dart's strong typing system, avoid dynamic types
- **Null Safety**: Proper null-aware programming with sound null safety
- **Immutability**: Use immutable data structures where appropriate
- **Resource Management**: Proper cleanup of timers, HTTP connections, and subscriptions

#### Best Practices

- **Documentation**: Clear dartdoc comments for public APIs
- **Testing**: Unit tests for business logic, integration tests for API interactions
- **Configuration**: Environment-based configuration management
- **Security**: Secure token handling, input validation, rate limiting
- **Performance**: Efficient API usage, proper caching strategies
- **Maintainability**: Clear naming conventions, modular design, easy to extend

#### Dart-Specific Standards

- **Effective Dart**: Follow official Dart style guide and best practices
- **Linting**: Adhere to strict linting rules (analysis_options.yaml configured)
- **Package Structure**: Proper library organization and exports
- **Future/Stream**: Appropriate use of Dart's asynchronous primitives

## Development Guidelines

- Write clean, readable, and maintainable code
- Implement proper error boundaries and graceful degradation
- Use dependency injection for testability
- Follow established patterns from the existing codebase
- Prioritize code clarity over cleverness
- Ensure all new features are thoroughly tested
- **CRITICAL: When debugging issues, ALWAYS investigate and understand the root cause first before attempting any fixes. Never apply random solutions without understanding why the problem occurs.**
- **NEVER make code changes or modifications unless explicitly requested by the user. Always ask for permission before making any changes.**
- **ALWAYS apply DRY (Don't Repeat Yourself) principle - eliminate code duplication through proper abstractions, helper functions, or code generation.**
- **STRICTLY follow user instructions exactly as given. Do not deviate, assume, or change the approach without explicit permission. If unclear, ask for clarification before proceeding.**
- **You may suggest alternatives if you believe the user's approach has issues, BUT you are ABSOLUTELY FORBIDDEN from implementing any alternatives without explicit user permission. NEVER implement suggestions automatically.**
- **NEVER revert changes or modify previous work without explicit user permission.**
- **If a user instruction seems difficult or impossible, continue attempting to fulfill it exactly as requested while optionally mentioning concerns.**
