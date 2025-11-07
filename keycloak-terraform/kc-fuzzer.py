#!/usr/bin/env python3
"""
kc-fuzzer.py

Keycloak load tester with interactive menu or automated fuzzing:
- Interactive mode: Choose specific client to test
- Automated mode: Randomly hit all clients with mix of valid/invalid credentials
- Supports both password grant and client_credentials
- Prints JWT payload on success
- Configurable concurrency, rate limiting, and duration
"""

"""
# What do you need to run this program:

sudo apt install python3-pip
sudo apt install python3-virtualenv
virtualenv $HOME/kc-fuzz
pip3 install requests
pip3 install aiohttp
pip3 install aiolimiter
"""

"""
# How you can run this program:

# Basic test - 30 seconds, 10 RPS
python3 kc_fuzz_tester.py

# High load test - 100 RPS for 5 minutes
python3 kc_fuzz_tester.py --rps 100 --duration 300 --concurrency 50

# All invalid requests (penetration testing)
python3 kc_fuzz_tester.py --valid-pct 0 --decode-payload

# Unlimited rate (stress test)
python3 kc_fuzz_tester.py --rps 0 --concurrency 100 --duration 60

"""

import asyncio
import aiohttp
import random
import string
import time
import argparse
import json
import base64
from aiolimiter import AsyncLimiter
from typing import Dict, Optional

# -------------------------
# Utility helpers (must be before config)
# -------------------------
def random_string(length=12):
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

# -------------------------
# Configuration
# -------------------------
KC_URL = "http://sso.local.io:32080"
MASTER_REALM = "master"
PLATFORM_REALM = "platform"

# Common credentials for platform realm users
PLATFORM_USERNAME = "bob"
PLATFORM_PASSWORD = ""

# Master realm credentials
MASTER_USERNAME = "admin"
MASTER_PASSWORD = "admin123"
MASTER_WRONG_PASSWORD = "admin123456"

# Client secrets (valid) for platform realm clients
SECRETS_MAP = {
  "argo-workflow": "e6PHVQUvrUIj4UQOiQa5ZQocOj0o9qDh",
  "argocd": "RbkuXPcyg49LIP8tVRwffxJEkCX4HQYw",
  "auth": "dlhUeaCEUOMdtgRUgojSAvLziFKIata7",
  "grafana": "9hUrr8g8ZAzCQlrmxjUbSnZUAMAYuGRT",
  "idp": "rSIcpfYC3v5leAsWVGdvrEjSHhmoZkTl",
  "secrets": "iVNhysbFvvfkNIg8C45bExpSBXNwUe9P",
  "storage": "1Bhf1L1OGGj5PkpYSViSw408aP4GxCZD"
}

# Auto-generate wrong secrets (10 chars each)
def generate_wrong_secrets(secrets_map: Dict[str, str], length: int = 10) -> Dict[str, str]:
    """Generate random wrong secrets for testing"""
    wrong_secrets = {}
    for client_id in secrets_map.keys():
        wrong_secrets[client_id] = random_string(length)
    return wrong_secrets

WRONG_SECRETS_MAP = generate_wrong_secrets(SECRETS_MAP)

# Define all clients (only unique properties)
CLIENTS = {
    "master": {
        "name": "Master Realm Login",
        "realm": MASTER_REALM,
        "grant_type": "password",
        "client_id": "admin-cli",
        "username": MASTER_USERNAME,
        "password": MASTER_PASSWORD,
        "wrong_password": MASTER_WRONG_PASSWORD
    },
    "argocd": {
        "name": "ArgoCD Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "argocd",
        "client_secret": SECRETS_MAP["argocd"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["argocd"]
    },
    "grafana": {
        "name": "Grafana Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "grafana",
        "client_secret": SECRETS_MAP["grafana"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["grafana"]
    },
    "argo-workflow": {
        "name": "Argo Workflow Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "argo-workflow",
        "client_secret": SECRETS_MAP["argo-workflow"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["argo-workflow"]
    },
    "oauth": {
        "name": "OAuth2 Proxy Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "auth",
        "client_secret": SECRETS_MAP["auth"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["auth"]
    },
    "secrets": {
        "name": "Vault/Secrets Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "secrets",
        "client_secret": SECRETS_MAP["secrets"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["secrets"]
    },
    "storage": {
        "name": "MinIO/Storage Client",
        "realm": PLATFORM_REALM,
        "grant_type": "password",
        "client_id": "secrets",
        "client_secret": SECRETS_MAP["storage"],
        "username": PLATFORM_USERNAME,
        "password": PLATFORM_PASSWORD,
        "wrong_client_secret": WRONG_SECRETS_MAP["storage"]
    }
}

# -------------------------
# Utility helpers
# -------------------------
def decode_jwt_payload(token: str):
    """Decode JWT payload (second part of token)"""
    try:
        parts = token.split('.')
        if len(parts) < 2:
            return "<invalid token format>"
        
        payload = parts[1]
        # Convert base64url to base64
        payload = payload.replace('-', '+').replace('_', '/')
        # Add padding
        pad = len(payload) % 4
        if pad:
            payload += '=' * (4 - pad)
        
        decoded = base64.b64decode(payload)
        return json.loads(decoded)
    except Exception as e:
        return f"<decode error: {e}>"

# -------------------------
# Stats tracking
# -------------------------
class Stats:
    def __init__(self):
        self.lock = asyncio.Lock()
        self.total = 0
        self.success = 0
        self.fail = 0
        self.codes = {}
        self.latencies = []
        self.max_latencies = 10000

    async def record(self, code: int, success: bool, latency: float):
        async with self.lock:
            self.total += 1
            if success:
                self.success += 1
            else:
                self.fail += 1
            self.codes[code] = self.codes.get(code, 0) + 1
            self.latencies.append(latency)
            if len(self.latencies) > self.max_latencies:
                self.latencies = self.latencies[-self.max_latencies:]

    async def snapshot(self):
        async with self.lock:
            s = {
                "total": self.total,
                "success": self.success,
                "fail": self.fail,
                "success_rate": f"{(self.success/self.total*100) if self.total > 0 else 0:.2f}%",
                "codes": dict(self.codes),
                "avg_latency_ms": round((sum(self.latencies)/len(self.latencies))*1000, 2) if self.latencies else 0,
            }
            return s

# -------------------------
# Request sender
# -------------------------
async def send_keycloak_request(
    session: aiohttp.ClientSession,
    client_key: str,
    use_wrong_credentials: bool = False,
    show_payload: bool = True,
    stats: Optional[Stats] = None
):
    """Send a single Keycloak token request"""
    cfg = CLIENTS[client_key]
    realm = cfg["realm"]
    url = f"{KC_URL}/realms/{realm}/protocol/openid-connect/token"
    
    # Build request data
    data = {
        "grant_type": cfg["grant_type"],
        "client_id": cfg["client_id"]
    }
    
    if cfg["grant_type"] == "password":
        # Use wrong credentials if requested
        if use_wrong_credentials:
            if "wrong_password" in cfg:
                data["password"] = cfg["wrong_password"]
            elif "wrong_client_secret" in cfg:
                data["client_secret"] = cfg["wrong_client_secret"]
            else:
                # Fuzz the password
                data["password"] = random_string(10)
            data["username"] = cfg.get("username", "bob")
            
            # Add client_secret if exists (even for password grant with wrong creds)
            if "client_secret" in cfg and "wrong_client_secret" not in cfg:
                data["client_secret"] = cfg["client_secret"]
        else:
            # Valid credentials
            data["username"] = cfg["username"]
            data["password"] = cfg["password"]
            if "client_secret" in cfg:
                data["client_secret"] = cfg["client_secret"]
    
    # Make request
    start = time.perf_counter()
    try:
        async with session.post(url, data=data, timeout=aiohttp.ClientTimeout(total=10)) as resp:
            latency = time.perf_counter() - start
            status = resp.status
            
            if status == 200:
                response_json = await resp.json()
                token = response_json.get('access_token', '')
                
                if stats:
                    await stats.record(status, True, latency)
                
                if show_payload and token:
                    payload = decode_jwt_payload(token)
                    print(f"✓ [{client_key}] Success (HTTP {status}) - {latency*1000:.0f}ms")
                    if isinstance(payload, dict):
                        print(f"  User: {payload.get('preferred_username', 'N/A')}")
                        print(f"  Email: {payload.get('email', 'N/A')}")
                        print(f"  Roles: {payload.get('realm_access', {}).get('roles', [])}")
                        print(f"  Groups: {payload.get('groups', [])}")
                    else:
                        print(f"  Payload: {payload}")
                return True
            else:
                text = await resp.text()
                
                if stats:
                    await stats.record(status, False, latency)
                
                if show_payload:
                    try:
                        error_json = json.loads(text)
                        error_desc = error_json.get('error_description', error_json.get('error', 'Unknown'))
                        print(f"✗ [{client_key}] Failed (HTTP {status}) - {error_desc}")
                    except:
                        print(f"✗ [{client_key}] Failed (HTTP {status}) - {text[:100]}")
                return False
                
    except asyncio.TimeoutError:
        latency = time.perf_counter() - start
        if stats:
            await stats.record(0, False, latency)
        if show_payload:
            print(f"✗ [{client_key}] Timeout")
        return False
    except Exception as e:
        latency = time.perf_counter() - start
        if stats:
            await stats.record(0, False, latency)
        if show_payload:
            print(f"✗ [{client_key}] Exception: {e}")
        return False

# -------------------------
# Interactive mode
# -------------------------
async def interactive_loop(client_key: str, use_wrong_credentials: bool = False):
    """Loop requests for a single client (like the shell script)"""
    cfg = CLIENTS[client_key]
    cred_type = "INVALID" if use_wrong_credentials else "VALID"
    
    print(f"\n{'='*60}")
    print(f"Looping {cfg['name']} with {cred_type} credentials")
    print(f"Realm: {cfg['realm']}, Client: {cfg['client_id']}")
    print(f"Press Ctrl+C to stop")
    print(f"{'='*60}\n")
    
    async with aiohttp.ClientSession() as session:
        try:
            while True:
                await send_keycloak_request(session, client_key, use_wrong_credentials, show_payload=True)
                await asyncio.sleep(3)
        except KeyboardInterrupt:
            print("\n\nStopped by user\n")

# -------------------------
# Automated fuzzing mode
# -------------------------
async def automated_fuzzing(
    duration: int,
    rps: int,
    concurrency: int,
    valid_pct: float,
    stats_interval: int
):
    """Randomly hit all clients with mix of valid/invalid credentials"""
    print(f"\n{'='*60}")
    print(f"Automated Fuzzing Mode")
    print(f"Duration: {duration}s, RPS: {rps}, Concurrency: {concurrency}")
    print(f"Valid requests: {valid_pct*100:.0f}%, Invalid: {(1-valid_pct)*100:.0f}%")
    print(f"{'='*60}\n")
    
    sem = asyncio.Semaphore(concurrency)
    limiter = AsyncLimiter(rps, 1) if rps > 0 else None
    stats = Stats()
    stop_event = asyncio.Event()
    
    # Stats printer
    async def print_stats():
        while not stop_event.is_set():
            try:
                await asyncio.wait_for(stop_event.wait(), timeout=stats_interval)
                break
            except asyncio.TimeoutError:
                snapshot = await stats.snapshot()
                print(f"\n--- Stats @ {time.strftime('%H:%M:%S')} ---")
                print(json.dumps(snapshot, indent=2))
    
    # Worker function
    async def worker():
        client_key = random.choice(list(CLIENTS.keys()))
        use_wrong = random.random() > valid_pct
        async with sem:
            await send_keycloak_request(
                session, 
                client_key, 
                use_wrong, 
                show_payload=False,  # Don't print individual requests
                stats=stats
            )
    
    connector = aiohttp.TCPConnector(limit=concurrency * 2)
    async with aiohttp.ClientSession(connector=connector) as session:
        start_time = time.time()
        printer_task = asyncio.create_task(print_stats())
        tasks = set()
        
        try:
            while True:
                elapsed = time.time() - start_time
                if duration > 0 and elapsed >= duration:
                    break
                
                if limiter:
                    await limiter.acquire()
                
                task = asyncio.create_task(worker())
                tasks.add(task)
                task.add_done_callback(tasks.discard)
                
                await asyncio.sleep(0.001)
                
        except KeyboardInterrupt:
            print("\n\nInterrupted, waiting for in-flight requests...\n")
        
        # Wait for remaining tasks
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
        
        stop_event.set()
        await printer_task
        
        # Final stats
        final = await stats.snapshot()
        print("\n" + "="*60)
        print("FINAL STATISTICS")
        print("="*60)
        print(json.dumps(final, indent=2))

# -------------------------
# Menu system
# -------------------------
def show_menu():
    print("\n" + "="*60)
    print("Keycloak Load Tester")
    print("="*60)
    print("\n With Valid Credentials:")
    print("  1) Master Realm Login")
    print("  2) ArgoCD Client")
    print("  3) Grafana Client")
    print("  4) Argo Workflow Client")
    print("  5) OAuth2 Proxy Client")
    print("  6) Secrets Client")
    print("  7) Storage Client")
    print("\n With Invalid Credentials:")
    print("  8) Master Realm Login")
    print("  9) ArgoCD Client")
    print(" 10) Grafana Client")
    print(" 11) Argo Workflow Client")
    print(" 12) OAuth2 Proxy Client")
    print(" 13) Secrets Client")
    print(" 14) Storage Client")
    print("\n Automated:")
    print(" 15) Random fuzzing (mix of valid/invalid)")
    print("  q) Quit")
    print("="*60)

def main():
    parser = argparse.ArgumentParser(description="Keycloak Load Tester")
    parser.add_argument("--auto", action="store_true", help="Skip menu, go straight to automated fuzzing")
    parser.add_argument("--duration", type=int, default=60, help="Duration in seconds for auto mode")
    parser.add_argument("--rps", type=int, default=10, help="Requests per second for auto mode")
    parser.add_argument("--concurrency", type=int, default=20, help="Concurrent requests for auto mode")
    parser.add_argument("--valid-pct", type=float, default=0.7, help="Percentage of valid requests (0-1)")
    parser.add_argument("--stats-interval", type=int, default=10, help="Stats print interval")
    args = parser.parse_args()
    
    if args.auto:
        # Go straight to automated mode
        try:
            asyncio.run(automated_fuzzing(
                duration=args.duration,
                rps=args.rps,
                concurrency=args.concurrency,
                valid_pct=args.valid_pct,
                stats_interval=args.stats_interval
            ))
        except KeyboardInterrupt:
            print("\nExiting...")
        return
    
    # Interactive menu
    client_map = {
        "1": ("master", False),
        "2": ("argocd", False),
        "3": ("grafana", False),
        "4": ("argo-workflow", False),
        "5": ("oauth", False),
        "6": ("secrets", False),
        "7": ("storage", True),
        "8": ("master", True),
        "9": ("argocd", True),
        "10": ("grafana", True),
        "11": ("argo-workflow", True),
        "12": ("oauth", True),
        "13": ("secrets", True),
        "14": ("storage", True),
    }
    
    while True:
        show_menu()
        choice = input("\nEnter your choice: ").strip()
        
        if choice.lower() in ['q', 'quit', 'exit']:
            print("Exiting...")
            break
        
        if choice == "15":
            # Automated fuzzing
            try:
                asyncio.run(automated_fuzzing(
                    duration=args.duration,
                    rps=args.rps,
                    concurrency=args.concurrency,
                    valid_pct=args.valid_pct,
                    stats_interval=args.stats_interval
                ))
            except KeyboardInterrupt:
                continue
        elif choice in client_map:
            client_key, use_wrong = client_map[choice]
            try:
                asyncio.run(interactive_loop(client_key, use_wrong))
            except KeyboardInterrupt:
                continue
        else:
            print("Invalid choice, try again.")

if __name__ == "__main__":
    main()