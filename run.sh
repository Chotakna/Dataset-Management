#!/usr/bin/env bash

MAD_PY="C:/Users/ROG/AppData/Local/Python/pythoncore-3.14-64/python.exe"
MAD_FLUTTER="D:/MAD/SDK/bin/flutter"
MAD_DIR="D:/MAD/Mad_Project"

echo "======================================"
echo "  Mad_Project - Full System Launcher  "
echo "======================================"
echo ""

cd "$MAD_DIR"

# ── Step 1: Kill stale processes ──
echo "[1/4] Cleaning up old processes..."
for pid in $(netstat -ano | grep 8000 | grep LISTENING | awk '{print $5}'); do
  taskkill /F /PID $pid 2>/dev/null
done
taskkill /F /IM flutter.exe 2>/dev/null
taskkill /F /IM dart.exe 2>/dev/null
sleep 2
echo "  Done"

# ── Step 2: Start Backend ──
echo "[2/4] Starting FastAPI backend..."
"$MAD_PY" -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --log-level warning &
BACKEND_PID=$!

for i in $(seq 1 10); do
  sleep 1
  RESP=$(curl -s http://localhost:8000/api/health 2>/dev/null)
  if [ "$RESP" = '{"status":"ok"}' ]; then
    echo "  ✅ Backend ready on http://localhost:8000"
    break
  fi
done

# ── Step 3: Launch Flutter (web) ──
echo "[3/4] Launching Flutter app in Chrome..."
echo ""
echo "======================================"
echo "  App will open in your browser."
echo "  Upload a .csv file from the Home tab"
echo "  to see ML features in action."
echo "======================================"
echo ""
"$MAD_FLUTTER" run -d chrome

# ── Cleanup on exit ──
echo "[4/4] Shutting down backend..."
kill $BACKEND_PID 2>/dev/null
echo "  Done. Bye!"
