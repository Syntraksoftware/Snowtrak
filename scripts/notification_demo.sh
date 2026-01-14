#!/bin/bash
# =============================================================================
# Syntrak Notification Demo
# =============================================================================
# Sends a sequence of different notification types to demonstrate the system.
# Run this while the Flutter app is running to see all notification types.
# =============================================================================

BASE_URL="http://127.0.0.1:8080/api/v1/notifications"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎿 Syntrak Notification Demo${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}This will send 6 different notifications with 3-second delays.${NC}"
echo -e "${BLUE}Make sure the Flutter app is running to see them!${NC}"
echo ""
read -p "Press Enter to start the demo..."
echo ""

# Function to send notification
send() {
    local TYPE=$1
    local TITLE=$2
    local MESSAGE=$3
    local SENDER=$4
    
    echo -e "${YELLOW}📤 Sending: $TYPE${NC}"
    
    if [ -n "$SENDER" ]; then
        curl -s -X POST "$BASE_URL/test" \
            -H "Content-Type: application/json" \
            -d "{\"type\": \"$TYPE\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\", \"sender_name\": \"$SENDER\"}" > /dev/null
    else
        curl -s -X POST "$BASE_URL/test" \
            -H "Content-Type: application/json" \
            -d "{\"type\": \"$TYPE\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\"}" > /dev/null
    fi
    
    echo -e "${GREEN}   ✓ $TITLE${NC}"
}

# Demo sequence
echo -e "${CYAN}[1/6] Kudos Notification${NC}"
send "kudos" "❤️ New Kudos!" "Sarah loved your morning ski run at Whistler!" "Sarah Chen"
sleep 3

echo -e "${CYAN}[2/6] Comment Notification${NC}"
send "comment" "💬 New Comment" "Mike: \"That was incredible! What trail?\"" "Mike Johnson"
sleep 3

echo -e "${CYAN}[3/6] Follow Notification${NC}"
send "follow" "👤 New Follower" "Alex Kim started following you" "Alex Kim"
sleep 3

echo -e "${CYAN}[4/6] Powder Day Alert${NC}"
send "powderDay" "❄️ POWDER DAY!" "18 inches of fresh snow at Whistler Blackcomb!"
sleep 3

echo -e "${CYAN}[5/6] Achievement Notification${NC}"
send "achievement" "🏆 Achievement Unlocked!" "You earned \"Speed Demon\" - Reached 60 km/h!"
sleep 3

echo -e "${CYAN}[6/6] Weather Alert${NC}"
send "weather" "⚠️ Weather Alert" "High winds expected at the summit. Gondola may close."

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Demo complete! Check the Flutter app for notifications.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
