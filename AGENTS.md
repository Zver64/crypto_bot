# Project Context

## Project Overview

This is a **Telegram Bot** built with **Dart** using the **Televerse**
framework. The bot provides cryptocurrency price monitoring and alerting
functionality, specifically tracking price changes from the Bybit exchange API.

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
- **NEVER directly modify pubspec.yaml to add dependencies. ALWAYS use Dart CLI commands (`dart pub add <package>` for dependencies, `dart pub add --dev <package>` for dev dependencies) to install the latest versions of packages.**
- always check your changes by running `dart analyze`
