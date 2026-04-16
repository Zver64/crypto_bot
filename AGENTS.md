# Project Codex Guide

## Purpose

This repository contains a Telegram bot written in Dart. It uses the
Televerse framework to monitor Bybit perpetual markets, estimate market-cap
driven volatility thresholds, and send alerts to subscribed Telegram users.

Treat this file as the project-specific operating guide for Codex and other
agents working in this repository.

## Non-Negotiable Rules

- Do not make code changes unless the user explicitly asks for them.
- Investigate root cause before proposing or implementing a fix.
- Follow the user's requested approach exactly. If something is unclear, ask.
- Do not revert existing work unless the user explicitly requests it.
- Do not edit `pubspec.yaml` directly to add dependencies. Use
  `dart pub add <package>` or `dart pub add --dev <package>`.
- After code changes, run `dart analyze`.
- Keep changes DRY, typed, null-safe, and production-oriented.

## Repository Map

- `bin/main.dart`: process entrypoint, BOT_TOKEN loading, Televerse bot setup,
  command registration, and conversation plugin wiring.
- `lib/handlers/`: Telegram command handlers and conversation handlers.
- `lib/services/`: price polling, subscription lifecycle, API access, batching,
  and global bot state.
- `lib/models/`: Bybit API models and generated JSON serializers.
- `lib/config/app_config.dart`: polling intervals and threshold defaults.
- `lib/utils/common.dart`: volatility calculation used to derive thresholds from
  market cap.
- `Makefile`: build and remote deploy helpers.
- `api_playground.http`: manual API inspection requests.

## Runtime Architecture

### Startup Flow

1. `bin/main.dart` loads `BOT_TOKEN` from the environment, then `.env`.
2. It creates `Bot`, enables `ConversationPlugin`, registers handlers, and
   starts polling.

### Command Surface

- `/start`: welcome message.
- `/subscribe`: adds the user to the in-memory subscriber set and starts polling
  timers if this is the first subscriber.
- `/unsubscribe`: removes the user and stops timers when the last subscriber
  leaves.
- `/setthreshold`: starts the threshold conversation flow.
- `/status`: reports current thresholds, subscriber count, and cache size.

### State Model

`lib/services/bot_state.dart` is the central in-memory state holder. Current
behavior depends on process-local state:

- subscriber ids
- active timers
- price threshold values
- circulating supply cache
- max notified prices

There is no persistence layer. A process restart clears all runtime state.
Preserve that assumption unless the user explicitly asks for persistence.

### Price Monitoring Flow

1. `SubscriptionService.subscribe` starts an immediate price check.
2. A periodic timer triggers `checkPrices`.
3. `ApiService.getBybitTickers` fetches Bybit linear tickers.
4. Movers above the coarse 24h change filter are selected.
5. Missing circulating supplies are fetched from CoinGecko in batches.
6. Market cap is estimated from current price and cached circulating supply.
7. `volatilityFromMcap` computes the dynamic alert threshold.
8. Alerts are sent only when the current price exceeds the previous notified
   maximum for a symbol.
9. Unreachable Telegram users are auto-removed from the subscriber set.

### Timer Lifecycle

When touching subscription logic, keep timer ownership consistent:

- `priceCheckTimer`: periodic alert checks
- `cacheRefreshTimer`: clears circulating supply cache periodically
- `midnightResetTimer`: resets per-symbol max notified prices daily

Avoid duplicate timers and always clean them up when the subscriber set becomes
empty.

## External Dependencies And Contracts

- Telegram Bot API through Televerse
- Bybit ticker endpoint:
  `https://api.bybit.com/v5/market/tickers?category=linear`
- CoinGecko markets endpoint for circulating supply lookup

Be careful when changing request volume, retry behavior, or batching. This bot
already uses batched CoinGecko calls plus inter-batch delay for rate limiting.

## Project-Specific Coding Guidance

### Preferred Design Direction

- Keep handlers thin and move business logic into services.
- Prefer dependency injection and instance-based services for new work when the
  user asks for refactoring or expansion.
- Preserve null safety and explicit typing.
- Use immutable value objects where practical.
- Surface failures clearly to both logs and Telegram users when appropriate.

### Current Technical Debt To Respect

- The code relies heavily on static state and static service methods.
- Logging is currently `print`-based.
- The README is still the default Dart template and should not be trusted as a
  source of project behavior.
- There is no existing test suite in the repository.

Do not silently "clean this up" unless the user asks. If you improve these
areas, explain the behavioral impact and preserve existing bot semantics.

### Generated Files

- `lib/models/bybit_models.g.dart` is generated output.
- If model fields change, regenerate code with `dart run build_runner build`.
- Do not hand-edit generated files unless the user explicitly asks for a manual
  patch and regeneration is not viable.

## Working Rules For Common Tasks

### When Debugging

- Reproduce the issue from the actual code path first.
- Identify whether the failure is in Telegram handling, timer lifecycle, Bybit
  parsing, CoinGecko lookup, threshold math, or in-memory state.
- Explain the root cause before applying a fix.

### When Adding Features

- Put Telegram interaction details in handlers and reusable logic in services.
- Avoid duplicating threshold, symbol normalization, or timer-management logic.
- Be careful with API fan-out, since naive loops can increase latency and rate
  limit risk.

### When Changing Alert Logic

- Preserve the relationship between:
  price change filter -> circulating supply lookup -> market cap estimate ->
  dynamic threshold -> max-notified-price guard
- Check whether the change affects duplicate alert suppression or cache usage.

## Validation

Run these as appropriate after code changes:

- `dart analyze`
- `dart test` if tests exist or were added
- `dart run build_runner build` if JSON models changed

If a command cannot be run, state that explicitly in the final response.

## Operational Notes

- Local token loading depends on `.env` or `BOT_TOKEN`.
- The build target in `Makefile` compiles a Linux executable.
- The deploy/start/stop targets operate on a remote host over SSH. Do not use
  them unless the user explicitly asks.

## What A Good Codex Contribution Looks Like Here

- Small, targeted changes with clear reasoning
- No hidden dependency additions
- No accidental timer leaks or duplicate background work
- No silent behavior changes in alert thresholds
- Clear validation notes after edits
