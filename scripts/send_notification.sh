#!/bin/bash
# =============================================================================
# Syntrak Notification Testing Script
# =============================================================================
# Send test notifications to the Flutter app from the command line.
#
# Usage:
#   ./send_notification.sh <type> <title> <message> [sender_name]
#
# Examples:
#   ./send_notification.sh kudos "New Kudos!" "Sarah liked your activity" "Sarah Chen"
#   ./send_notification.sh powder-day "Powder Alert" "8 inches at Whistler!"
#   ./send_notification.sh achievement "Achievement!" "You unlocked Speed Demon"
#
# Quick test commands (no arguments needed):
#   ./send_notification.sh test-kudos
#   ./send_notification.sh test-comment
#   ./send_notification.sh test-follow
#   ./send_notification.sh test-powder
#   ./send_notification.sh test-achievement
#   ./send_notification.sh test-weather
# =============================================================================

BASE_URL="http://127.0.0.1:8080/api/v1/notifications"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show usage
show_usage() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔔 Syntrak Notification Tester${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Quick Tests (no arguments):${NC}"
    echo "  ./send_notification.sh test-kudos       - Test kudos notification"
    echo "  ./send_notification.sh test-comment     - Test comment notification"
    echo "  ./send_notification.sh test-follow      - Test follow notification"
    echo "  ./send_notification.sh test-powder      - Test powder day alert"
    echo "  ./send_notification.sh test-achievement - Test achievement notification"
    echo "  ./send_notification.sh test-weather     - Test weather alert"
    echo ""
    echo -e "${GREEN}Custom Notification:${NC}"
    echo "  ./send_notification.sh <type> <title> <message> [sender]"
    echo ""
    echo -e "${GREEN}Types:${NC} kudos, comment, follow, friendActivity, challenge,"
    echo "        group, weather, powderDay, achievement, system"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo '  ./send_notification.sh kudos "❤️ Kudos!" "Sarah liked your run" "Sarah"'
    echo '  ./send_notification.sh achievement "🏆 New Badge!" "Speed Demon unlocked"'
    echo ""
}

# Send custom notification
send_custom() {
    local TYPE=$1
    local TITLE=$2
    local MESSAGE=$3
    local SENDER=$4

    echo -e "${YELLOW}📤 Sending notification...${NC}"
    
    if [ -n "$SENDER" ]; then
        PAYLOAD="{\"type\": \"$TYPE\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\", \"sender_name\": \"$SENDER\"}"
    else
        PAYLOAD="{\"type\": \"$TYPE\", \"title\": \"$TITLE\", \"message\": \"$MESSAGE\"}"
    fi

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/test" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Notification sent successfully!${NC}"
        echo -e "${BLUE}Response:${NC} $BODY"
    else
        echo -e "${RED}❌ Failed to send notification (HTTP $HTTP_CODE)${NC}"
        echo -e "${RED}Make sure the backend is running: cd backend/main-backend && python run.py${NC}"
    fi
}

# Quick test functions
test_kudos() {
    echo -e "${YELLOW}🔔 Sending KUDOS notification...${NC}"
    curl -s -X POST "$BASE_URL/test/kudos" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

test_comment() {
    echo -e "${YELLOW}🔔 Sending COMMENT notification...${NC}"
    curl -s -X POST "$BASE_URL/test/comment" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

test_follow() {
    echo -e "${YELLOW}🔔 Sending FOLLOW notification...${NC}"
    curl -s -X POST "$BASE_URL/test/follow" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

test_powder() {
    echo -e "${YELLOW}🔔 Sending POWDER DAY notification...${NC}"
    curl -s -X POST "$BASE_URL/test/powder-day" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

test_achievement() {
    echo -e "${YELLOW}🔔 Sending ACHIEVEMENT notification...${NC}"
    curl -s -X POST "$BASE_URL/test/achievement" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

test_weather() {
    echo -e "${YELLOW}🔔 Sending WEATHER notification...${NC}"
    curl -s -X POST "$BASE_URL/test/weather" | python3 -m json.tool 2>/dev/null || echo "Sent!"
    echo -e "${GREEN}✅ Done!${NC}"
}

# Main logic
case "$1" in
    test-kudos)
        test_kudos
        ;;
    test-comment)
        test_comment
        ;;
    test-follow)
        test_follow
        ;;
    test-powder)
        test_powder
        ;;
    test-achievement)
        test_achievement
        ;;
    test-weather)
        test_weather
        ;;
    ""|help|-h|--help)
        show_usage
        ;;
    *)
        if [ $# -lt 3 ]; then
            echo -e "${RED}Error: Custom notification requires at least 3 arguments${NC}"
            echo ""
            show_usage
            exit 1
        fi
        send_custom "$1" "$2" "$3" "$4"
        ;;
esac
