@echo off
echo Adding test daily prices to Firestore...
echo.

REM Use Firebase CLI to add data directly
firebase firestore:set daily_prices/test-2025-11-18 "{\"unit_id\":\"apartman-1\",\"date\":{\"_seconds\":1731888000,\"_nanoseconds\":0},\"price\":50,\"created_at\":{\"_seconds\":1729872000,\"_nanoseconds\":0}}"

firebase firestore:set daily_prices/test-2025-11-19 "{\"unit_id\":\"apartman-1\",\"date\":{\"_seconds\":1731974400,\"_nanoseconds\":0},\"price\":50,\"created_at\":{\"_seconds\":1729872000,\"_nanoseconds\":0}}"

firebase firestore:set daily_prices/test-2025-11-20 "{\"unit_id\":\"apartman-1\",\"date\":{\"_seconds\":1732060800,\"_nanoseconds\":0},\"price\":60,\"created_at\":{\"_seconds\":1729872000,\"_nanoseconds\":0}}"

firebase firestore:set daily_prices/test-2025-11-21 "{\"unit_id\":\"apartman-1\",\"date\":{\"_seconds\":1732147200,\"_nanoseconds\":0},\"price\":55,\"created_at\":{\"_seconds\":1729872000,\"_nanoseconds\":0}}"

echo.
echo Done! Added 4 test prices.
echo Check calendar at: https://rab-booking-248fc.web.app/?unit=apartman-1
pause
