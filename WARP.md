# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is the **Wellington FinTech Rails API** - a learning project demonstrating Rails development with New Zealand regulatory compliance research. The project shows understanding of RBNZ, IRD, and FMA requirements through sample data and API structure.

**Current Status**: This is a demonstration/learning repository with Rails application structure, sample compliance data, and development environment configuration.

## Quick Start

### GitHub Codespaces (Recommended)
**One-click development environment with full NZ compliance stack:**

1. **Open in Codespaces**: Click "Code" > "Codespaces" > "Create codespace on main"
2. **Automatic setup**: The `.devcontainer` will automatically:
   - Set up Ruby 3.1.0 + Rails environment
   - Launch PostgreSQL 15 + Redis 7
   - Install all dependencies and gems
   - Create and seed database with NZ compliance data
   - Configure VS Code with Rails extensions
3. **Start developing**: Server will be available at `https://[codespace-name]-3000.app.github.dev`

```bash
# Once Codespace is ready:
bundle exec rails server -b 0.0.0.0  # Start server
curl http://localhost:3000/api/v1/status  # Test API
```

### Local Development (Alternative)
- Ruby 3.1.0+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose

```bash
# Use the full Rails Gemfile
cp Gemfile.complex Gemfile
bundle install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Start services with Docker
docker-compose up -d

# Start Rails server
rails server
```

### Health Check
```bash
# Check API health (once implemented)
curl http://localhost:3000/health
curl http://localhost:3000/api/v1/status
```

## Architecture Overview

### Tech Stack (from Gemfile)
- **Rails 7.1** - API-only mode with advanced features
- **PostgreSQL 15** - Primary database with JSONB support
- **Redis** - Caching and session management
- **Sidekiq** - Background job processing for financial operations

### Key Architectural Components

#### Authentication & Security
- **JWT tokens** with RS256 signing for stateless authentication
- **bcrypt** for password hashing
- **rack-cors** for cross-origin resource sharing
- **rack-attack** for rate limiting and DDoS protection
- **lockbox** for field-level encryption of sensitive data
- **blind_index** for encrypted search capabilities

#### Financial Data Handling
- **money-rails** & **ruby-money** for precise currency calculations
- **chronic** for natural language date parsing
- **business_time** for business day calculations
- **holidays** gem with NZ holiday support

#### API Documentation & Testing
- **rswag** suite for Swagger/OpenAPI 3.0 documentation
- **RSpec** with **factory_bot_rails** for testing
- **VCR** & **webmock** for HTTP interaction recording
- **timecop** for time-based testing scenarios

#### NZ-Specific Integrations
- **xero-ruby** for Xero accounting platform integration
- **faraday** with retry middleware for banking API calls
- **nokogiri** for XML parsing (government APIs)

## Development Commands

### GitHub Codespaces Commands
```bash
# Server management
bundle exec rails server -b 0.0.0.0    # Start Rails server (accessible externally)
bundle exec sidekiq                     # Start background jobs

# Database operations
rails db:migrate                        # Run migrations
rails db:seed                          # Load NZ compliance sample data
rails console                          # Rails console

# Testing & Quality
rspec                                  # Run test suite
rubocop                               # Code style check
brakeman                              # Security scan

# API testing
curl https://$(echo $CODESPACE_NAME)-3000.app.github.dev/health
curl https://$(echo $CODESPACE_NAME)-3000.app.github.dev/api/v1/status
```

### Local Development Setup
```bash
bundle install                    # Install gems
rails db:setup                   # Create and seed database
docker-compose up -d             # Start supporting services
```

### Code Quality & Security
```bash
rubocop                          # Ruby style checking
rubocop --auto-correct           # Auto-fix style issues
brakeman                         # Security vulnerability scan
bundler-audit                    # Check for vulnerable dependencies
```

### Testing
```bash
rspec                           # Run full test suite
rspec spec/requests/            # Run API request specs
rspec spec/models/              # Run model specs
rswag:specs:swaggerize         # Generate API documentation from specs
```

### Development Server
```bash
rails server                    # Start Rails API server
sidekiq                         # Start background job processor (separate terminal)
rails console                  # Interactive Rails console
rails console --sandbox        # Safe console mode (auto-rollback)
```

### Database Operations
```bash
rails db:migrate               # Run pending migrations
rails db:rollback             # Rollback last migration
rails db:seed                 # Load seed data
rails db:reset               # Drop, create, migrate, and seed
```

### Docker Operations
```bash
docker-compose up -d          # Start all services in background
docker-compose logs web       # View Rails app logs
docker-compose exec web bash # Shell into Rails container
docker-compose down           # Stop all services
```

## NZ Financial Compliance Framework

### RBNZ (Reserve Bank of New Zealand) Requirements
- **Audit logging**: Comprehensive transaction trails using Rails default logging plus custom audit models
- **Capital adequacy reporting**: Background jobs to generate BS2A and BS15 reports
- **API rate limiting**: Protect against abuse while maintaining availability
- **Data retention**: 7-year minimum for financial transaction records

### IRD (Inland Revenue Department) Integration
- **GST calculation**: Automated tax calculation using money-rails precision
- **Real-time reporting**: Background jobs for tax submission workflows
- **Business activity statements**: Automated generation and filing
- **Multi-currency support**: For international transaction tax implications

### FMA (Financial Markets Authority) Compliance
- **AML/CFT workflows**: Customer due diligence and transaction monitoring
- **KYC verification**: Identity verification process automation
- **Suspicious activity reporting**: Automated flagging and reporting systems
- **Client data protection**: Field-level encryption for sensitive customer data

## Key Architectural Patterns

### API Structure
```bash
app/
├── controllers/
│   └── api/
│       └── v1/              # Versioned API controllers
├── services/                # Business logic layer
├── serializers/             # JSON API response formatting
├── models/                  # Domain models with financial validations
└── jobs/                   # Sidekiq background jobs
```

### Request/Response Flow
1. **Controller** receives request and validates parameters
2. **Service objects** handle business logic and compliance checks
3. **Models** perform data validation and persistence
4. **Serializers** format JSON responses
5. **Background jobs** handle async operations (reporting, notifications)

### Security Layers
1. **Rate limiting** via rack-attack
2. **JWT authentication** with configurable expiry
3. **Field-level encryption** for PII and financial data
4. **Audit logging** for all financial operations
5. **HTTPS enforcement** in production

## Testing Strategy

### RSpec Test Types
- **Request specs**: Full API endpoint testing
- **Model specs**: Domain logic and validation testing  
- **Service specs**: Business logic testing
- **Job specs**: Background job testing with rspec-sidekiq

### Financial Testing Patterns
- Use **FactoryBot** for realistic financial test data
- **VCR cassettes** for external API integration testing
- **Timecop** for testing time-sensitive financial calculations
- **Database cleaner** for transaction isolation

## Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check PostgreSQL is running
docker-compose ps db

# Reset database if corrupted
rails db:drop db:create db:migrate db:seed
```

#### Redis Connection Issues
```bash
# Check Redis connectivity
docker-compose logs redis
redis-cli ping  # Should return PONG
```

#### Background Job Processing
```bash
# Check Sidekiq status
bundle exec sidekiq -e development -C config/sidekiq.yml

# Clear failed jobs
Sidekiq::RetrySet.new.clear
```

### Financial Data Precision Issues
- Always use `Money` objects for currency calculations
- Never use `Float` for financial amounts
- Validate currency codes against ISO 4217 standards
- Test edge cases with fractional cents

## Future Development Notes

### Pending Implementation
This repository currently contains planning documentation. Future WARP sessions should:

1. **Generate Rails application structure**: `rails new . --api --database=postgresql`
2. **Implement API versioning**: Set up `/api/v1` namespace
3. **Configure JWT authentication**: Implement user authentication system
4. **Set up compliance logging**: Audit trail models and middleware
5. **Create financial models**: Account, Transaction, Payment domain models
6. **Implement NZ integrations**: Xero, IRD, and banking API clients

### Integration Priorities
1. **Xero API integration** - Chart of accounts synchronization
2. **IRD Gateway** - Tax calculation and filing automation  
3. **Open Banking NZ** - Account aggregation and payment initiation
4. **RBNZ reporting** - Regulatory compliance automation

### Performance Optimizations
- Implement database connection pooling
- Add Redis caching for frequent API calls
- Set up background job queues for heavy operations
- Configure CDN for API documentation assets

---

**Note**: This WARP.md will be updated as the Rails application structure is implemented and architectural decisions are finalized.