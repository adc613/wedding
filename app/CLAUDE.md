# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Phoenix/Elixir wedding website application for managing wedding RSVPs, guest management, and wedding information. The application uses Phoenix LiveView for interactive features and SQLite for data storage.

## Tech Stack

- **Language**: Elixir (v1.14+)
- **Framework**: Phoenix Framework (v1.7.19) with LiveView (v1.0.0)
- **Database**: SQLite with Ecto ORM
- **Frontend**: HEEx templates with Tailwind CSS
- **Authentication**: Phoenix built-in authentication system
- **Email**: Swoosh with Amazon SES integration

## Common Commands

```bash
# Development
mix phx.server           # Start development server (localhost:4000)
iex -S mix phx.server    # Start with interactive shell

# Setup and database
mix setup                # Install deps, setup DB, build assets
mix ecto.setup           # Create, migrate, seed database
mix ecto.reset           # Drop and recreate database

# Assets
mix assets.setup         # Install Tailwind/ESBuild
mix assets.build         # Build CSS/JS assets
mix assets.deploy        # Build and optimize for production

# Testing
mix test                 # Run test suite
mix test --watch         # Run tests with file watching
mix test test/path/file_test.exs  # Run single test file
```

## Architecture

### Directory Structure
- `lib/app/` - Core business logic (contexts and schemas)
- `lib/app_web/` - Web interface (controllers, live views, components)
- `lib/app/accounts/` - User authentication system
- `lib/app/guest/` - Guest management (Guest, Invitation, RSVP models)
- `test/` - Test files mirroring lib structure

### Key Domain Models
- **Guest**: Individual wedding guests with contact info and preferences
- **Invitation**: Groups of guests invited together
- **RSVP**: Response tracking for wedding events
- **User**: Admin users for system management

### Phoenix Contexts
The application follows Phoenix context patterns:
- `App.Accounts` - User authentication and management
- `App.Guest` - Guest, invitation, and RSVP management

## Development Environment

- Development server: `localhost:4000`
- Test environment: `localhost:4002`
- Database files: `app_dev.db`, `app_test.db`
- Live reload enabled for templates and assets

## Key Features

### Public Pages
- Home, Story, Photos, Travel, Registry, Things to Do pages
- RSVP system with guest lookup and event confirmation
- Plus-one management for guests

### Admin Dashboard
- Guest management and invitation tracking
- STD (Save The Date) management
- Protected by authentication system

## Testing

Uses ExUnit with test cases organized by:
- `AppWeb.ConnCase` for controller tests
- `AppWeb.LiveViewCase` for LiveView tests  
- `App.DataCase` for context/schema tests

## Configuration

- `config/dev.exs` - Development settings
- `config/test.exs` - Test environment
- `config/prod.exs` - Production with SSL and SES email
- `config/runtime.exs` - Runtime environment variables

## Database

SQLite database with Ecto migrations in `priv/repo/migrations/`. Key tables include guests, invitations, rsvps, and users.

## Deployment

Production deployment uses:
- Containerization with Dockerfile
- SSL certificates with Let's Encrypt
- Domain: `wedding.adamcollins.io`
- Environment variables for database path, secret key, and AWS SES credentials