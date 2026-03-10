#!/bin/bash

# Pokémon Stadium Lite - Quick Start Script

echo "==================================="
echo "Pokémon Stadium Lite - Quick Start"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if MongoDB is running
echo "Checking MongoDB..."
if command -v mongod &> /dev/null; then
    echo -e "${GREEN}✓ MongoDB found${NC}"
else
    echo -e "${YELLOW}! MongoDB not found. Install or start MongoDB separately.${NC}"
    echo "  mongod --dbpath ./data/db"
fi

echo ""
echo "=== BACKEND SETUP ==="
echo ""

cd backend

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing backend dependencies..."
    npm install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${RED}✗ Failed to install dependencies${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ node_modules found${NC}"
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << 'ENVFILE'
MONGODB_URI=mongodb://localhost:27017/pokemon_stadium
PORT=8080
NODE_ENV=development
ENVFILE
    echo -e "${GREEN}✓ .env created${NC}"
    echo "  Edit .env if needed for MongoDB connection"
else
    echo -e "${GREEN}✓ .env already exists${NC}"
fi

# Check syntax
echo "Checking backend syntax..."
node --check src/app.js > /dev/null 2>&1 && \
node --check server.js > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ No syntax errors${NC}"
else
    echo -e "${RED}✗ Syntax errors found${NC}"
    exit 1
fi

echo ""
echo "=== BACKEND READY ==="
echo ""
echo -e "${GREEN}To start backend:${NC}"
echo "  cd backend"
echo "  npm run dev"
echo ""
echo "Expected: Server listening on 0.0.0.0:8080"
echo ""

cd ..

echo "=== FLUTTER SETUP ==="
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found${NC}"
    echo "  Install Flutter from https://flutter.dev"
    exit 1
fi

echo -e "${GREEN}✓ Flutter found${NC}"

# Check pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    exit 1
fi

echo "Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies ready${NC}"
else
    echo -e "${YELLOW}! Check Flutter dependencies manually${NC}"
fi

echo ""
echo "=== FLUTTER READY ==="
echo ""
echo -e "${GREEN}To start Flutter app:${NC}"
echo "  flutter run"
echo ""
echo "Expected: App prompts for backend URL"
echo ""

echo ""
echo "==================================="
echo -e "${GREEN}SETUP COMPLETE${NC}"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. Start MongoDB (if not running)"
echo "2. Open terminal 1: cd backend && npm run dev"
echo "3. Open terminal 2: flutter run"
echo "4. Enter backend URL when prompted (http://your-ip:8080)"
echo "5. Test with 2 players (use different devices/emulators)"
echo ""

