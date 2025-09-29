# ARCHITECTURE.md

## Purpose
This document outlines the key architecture decisions, patterns, and rationale for the app. Use it to record and communicate how and why the app is structured the way it is.

## 1. Overview
- **App Name:**
- **Description:**
- **Main Technologies:** (e.g., Flutter, Dart, REST API, etc.)
- **Target Platforms:** Web, iOS, Android

## 2. High-Level Architecture
- **Diagram:** (Insert or link to a diagram if available)
- **Layers/Modules:**
  - UI Layer:
  - Business Logic Layer:
  - Data Layer:
  - Other:

## 3. Key Decisions
- **State Management:** (e.g., Provider, Bloc, Riverpod, setState, etc.)
- **Navigation:** (e.g., Navigator 2.0, named routes)
- **Dependency Injection:**
- **Networking:** (e.g., http, dio)
- **Persistence:** (e.g., shared_preferences, SQLite)
- **Testing:**

## 4. Rationale
- Why were these technologies and patterns chosen?
- What alternatives were considered?

## 5. Future Considerations
- Planned refactors or improvements
- Technical debt

## 6. References
- Links to relevant docs, ADRs, or resources

## Core concept
- Playable offline, does not require network to be able to play (only needed when first time running the app or when game is updated with new puzzles like daily puzzles)
- Puzzles are auto-generated with possibility to human-generate (requires an algorithm to spead the characters on the game grid)

---

> Update this document as the architecture evolves. This helps new and existing team members understand the app's structure and reasoning.
