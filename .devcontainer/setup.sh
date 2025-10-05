#!/bin/bash
set -e

echo "🏦 Setting up Wellington FinTech Rails API Codespace..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to start..."
until pg_isready -h postgres -p 5432 -U wellington; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done
echo "✅ PostgreSQL is ready!"

# Use the complex Gemfile with all Rails dependencies
if [ -f "Gemfile.complex" ]; then
  echo "📦 Using complex Gemfile with full Rails stack..."
  cp Gemfile.complex Gemfile
else
  echo "⚠️ Gemfile.complex not found, using existing Gemfile"
fi

# Install Ruby dependencies
echo "💎 Installing Ruby gems..."
gem install bundler
bundle install

# Create database if it doesn't exist
echo "🗄️ Setting up database..."
if bundle exec rails db:version > /dev/null 2>&1; then
  echo "Database already exists, running migrations..."
  bundle exec rails db:migrate
else
  echo "Creating database..."
  bundle exec rails db:create
  bundle exec rails db:migrate
fi

# Seed the database with NZ compliance data
echo "🌱 Seeding database with sample data..."
bundle exec rails db:seed

# Set up development tools
echo "🛠️ Setting up development tools..."
bundle exec rails generate rspec:install 2>/dev/null || echo "RSpec already initialized"

# Create necessary directories
mkdir -p tmp/pids
mkdir -p log
mkdir -p public

# Install Node dependencies if package.json exists
if [ -f "package.json" ]; then
  echo "📦 Installing Node.js dependencies..."
  npm install
fi

echo "✅ Wellington FinTech Rails API Codespace setup complete!"
echo ""
echo "🚀 Quick Start Commands:"
echo "  • Start server: bundle exec rails server -b 0.0.0.0"
echo "  • Run tests: bundle exec rspec"
echo "  • Console: bundle exec rails console"
echo "  • Check status: curl http://localhost:3000/api/v1/status"
echo ""
echo "🔗 The API will be available at: https://[codespace-name]-3000.app.github.dev"