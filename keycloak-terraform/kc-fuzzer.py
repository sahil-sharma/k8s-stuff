#!/usr/bin/env python3
import asyncio
import aiohttp
import random
import string
import time
import argparse
import json
import base64
import os
from aiolimiter import AsyncLimiter

# -------------------------
# Configuration
# -------------------------
KC_URL = os.getenv("KC_URL", "http://sso.local.io:32080")
PLATFORM_REALM = "platform"

# Valid Credentials
USER = os.getenv("KC_USER", "bob")
PASS = os.getenv("KC_PASSWORD", "98DXLAV7W7dEksHM")

# Client Registry (Fixed mapping)
CLIENTS ={
  "argo-workflow": {
    "id": "argo-workflow",
    "secret": "8XGzN2RciMNXaFyCXB7F2nwoblMYM2hd"
  },
  "argocd": {
    "id": "argocd",
    "secret": "wUFdh34xj8r0W23uK5Fzk5PLStbSvniX"
  },
  "auth": {
    "id": "auth",
    "secret": "s3xzs45OrsKSU07ge6NavBocfVuUfgbJ"
  },
  "grafana": {
    "id": "grafana",
    "secret": "zma9p2jbxu5lFsNtWHYZBzHG35YDpvZA"
  },
  "kafka-authz-idp-broker": {
    "id": "kafka-authz-idp-broker",
    "secret": "G2k5tTwbGCoMxJIOwD4TocUWnZxQxegm"
  },
  "kiali": {
    "id": "kiali",
    "secret": "uLYrxq47DAKYxewjQBJJgogAoYqGYgeb"
  },
  "secrets": {
    "id": "secrets",
    "secret": "pU4pqGfURHPcdXjealSy6zIyUtiKR2Dj"
  },
  "storage": {
    "id": "storage",
    "secret": "5tzmSL00QCZ4kSlw8lFfx6MTFf7izdM7"
  }
}

# -------------------------
# Stats Engine
# -------------------------
class Stats:
    def __init__(self):
        self.lock = asyncio.Lock()
        self.metrics = {"success": 0, "auth_fail": 0, "error": 0}
        self.status_codes = {}
        self.latencies = []

    async def record(self, code, latency):
        async with self.lock:
            self.status_codes[code] = self.status_codes.get(code, 0) + 1
            if code == 200:
                self.metrics["success"] += 1
            elif code in [401, 400]:
                self.metrics["auth_fail"] += 1
            else:
                self.metrics["error"] += 1
            self.latencies.append(latency)

    async def report(self):
        async with self.lock:
            total = sum(self.status_codes.values()) or 1
            avg_lat = (sum(self.latencies)/len(self.latencies)*1000) if self.latencies else 0
            print(f"\n[METRICS] Total: {total} | Success: {self.metrics['success']} | "
                  f"Auth Fails: {self.metrics['auth_fail']} | Avg Latency: {avg_lat:.2f}ms")
            print(f"[STATUS CODES] {self.status_codes}")

# -------------------------
# Fuzzing Logic
# -------------------------
async def fire_request(session, stats, valid_pct):
    client_key = random.choice(list(CLIENTS.keys()))
    cfg = CLIENTS[client_key]
    url = f"{KC_URL}/realms/{PLATFORM_REALM}/protocol/openid-connect/token"

    is_valid = random.random() < valid_pct

    # Ensure these match your LATEST terraform output
    data = {
        "grant_type": "password",
        "client_id": cfg["id"],
        "username": USER,
        "password": PASS if is_valid else f"wrong_{random.randint(100,999)}",
        "client_secret": cfg["secret"]
    }

    # Force the correct header for Keycloak
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    start = time.perf_counter()
    try:
        # Pass headers explicitly
        async with session.post(url, data=data, headers=headers, timeout=5) as resp:
            # Debugging: Print body on failure to see why Keycloak is mad
            if resp.status != 200:
                error_text = await resp.text()
                # print(f"Error {resp.status}: {error_text}")
            await stats.record(resp.status, time.perf_counter() - start)
    except Exception:
        await stats.record(0, 0)

# -------------------------
# Worker Architecture
# -------------------------

async def worker(session, stats, limiter, valid_pct, stop_event):
    while not stop_event.is_set():
        if limiter:
            await limiter.acquire()
        await fire_request(session, stats, valid_pct)

async def run_load_test(args):
    stats = Stats()
    limiter = AsyncLimiter(args.rps, 1) if args.rps > 0 else None
    stop_event = asyncio.Event()

    # Use a high-performance connector for load testing
    conn = aiohttp.TCPConnector(limit=args.concurrency, ttl_dns_cache=300)
    async with aiohttp.ClientSession(connector=conn) as session:
        workers = [asyncio.create_task(worker(session, stats, limiter, args.valid_pct, stop_event))
                   for _ in range(args.concurrency)]

        print(f"Testing {KC_URL}...")
        try:
            for _ in range(0, args.duration, args.interval):
                await asyncio.sleep(args.interval)
                await stats.report()
        except KeyboardInterrupt:
            pass
        finally:
            stop_event.set()
            await asyncio.gather(*workers, return_exceptions=True)
            print("\n--- FINAL RUN REPORT ---")
            await stats.report()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--rps", type=int, default=20, help="Target Requests Per Second")
    parser.add_argument("--concurrency", type=int, default=10, help="Number of parallel workers")
    parser.add_argument("--duration", type=int, default=60, help="Test duration in seconds")
    parser.add_argument("--valid-pct", type=float, default=0.7, help="Ratio of valid (200) vs invalid (401) reqs")
    parser.add_argument("--interval", type=int, default=5, help="Reporting interval")

    args = parser.parse_args()
    asyncio.run(run_load_test(args))
