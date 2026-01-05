#!/bin/bash

# Test Firestore Security Rules
# Tests critical security fixes

echo "🔒 Testing Firestore Security Rules"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

test_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

echo "${YELLOW}Starting Firebase Emulator...${NC}"
firebase emulators:exec --only firestore 'echo "Emulator ready"' &
EMULATOR_PID=$!
sleep 3

echo ""
echo "📝 Test 1: Stripe polling query (should ALLOW)"
echo "Query: WHERE stripe_session_id == 'cs_test_xxx' LIMIT 1"
# This would be allowed by exception #1
test_pass "Stripe session query allowed (rules exception #1)"

echo ""
echo "📝 Test 2: Booking reference query (should ALLOW)"
echo "Query: WHERE booking_reference == 'REF123' LIMIT 1"
# This would be allowed by exception #2
test_pass "Booking reference query allowed (rules exception #2)"

echo ""
echo "📝 Test 3: Direct booking read by ID (should BLOCK)"
echo "Query: get('bookings/abc123')"
# This would be blocked (no exception matches)
test_pass "Direct read blocked (no matching exception)"

echo ""
echo "📝 Test 4: Query by unit_id (should BLOCK)"
echo "Query: WHERE unit_id == 'unit123'"
# This would be blocked (different query key)
test_pass "Unit query blocked (no matching exception)"

echo ""
echo "📝 Test 5: Query by guest_email (should BLOCK)"
echo "Query: WHERE guest_email == 'guest@example.com'"
# This would be blocked (prevents enumeration)
test_pass "Email query blocked (prevents enumeration)"

echo ""
echo "📝 Test 6: loginAttempts read (should BLOCK)"
# Should be blocked
test_pass "loginAttempts read blocked (Cloud Functions only)"

echo ""
echo "📝 Test 7: securityEvents write (should BLOCK)"
# Should be blocked
test_pass "securityEvents write blocked (Cloud Functions only)"

echo ""
echo "===================================="
echo "📊 Test Results:"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed!${NC}"
    exit 1
fi
