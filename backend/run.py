"""
Unified Backend Orchestrator.
Starts all four backend services or individual services using a shared venv.

Usage:
    python run.py                    # Start all services
    python run.py --all              # Start all services
    python run.py --service main     # Start just main-backend (auth, users)
    python run.py --service community     # Start just community-backend
    python run.py --service activity      # Start just activity-backend
    python run.py --service map           # Start just map-backend
"""
import sys
import subprocess
import os
from pathlib import Path

# Root backend directory
backend_directory = Path(__file__).parent

# Service configurations: name -> (service_dir, port, host)
SERVICES = {
    "main": {
        "dir": backend_directory / "main-backend",
        "port": 8080,
        "host": "0.0.0.0",
        "module": "app.main:app",  # Uses uvicorn config from run.py
        "description": "🔐 Auth & Core APIs"
    },
    "community": {
        "dir": backend_directory / "community-backend",
        "port": 5001,
        "host": "0.0.0.0",
        "description": "👥 Community (posts, threads, comments)"
    },
    "activity": {
        "dir": backend_directory / "activity-backend",
        "port": 5100,
        "host": "127.0.0.1",
        "description": "🎿 Activity tracking (GPS, kudos)"
    },
    "map": {
        "dir": backend_directory / "map-backend",
        "port": 5200,
        "host": "127.0.0.1",
        "description": "🗺️ Maps & elevation"
    }
}

# Path to shared venv
VENV_PYTHON = backend_directory / ".venv" / "bin" / "python"

def start_service(service_name):
    """Start a single service using the shared venv."""
    if service_name not in SERVICES:
        print(f"❌ Unknown service: {service_name}")
        print(f"Available services: {', '.join(SERVICES.keys())}")
        return False
    
    service = SERVICES[service_name]
    service_dir = service["dir"]
    
    if not service_dir.exists():
        print(f"❌ Service directory not found: {service_dir}")
        return False
    
    print(f"\n🚀 Starting {service['description']} on port {service['port']}...")
    print(f"   Directory: {service_dir}")
    print(f"   Command: {VENV_PYTHON} run.py\n")
    
    try:
        # Change to service directory and run its run.py with shared venv
        result = subprocess.run(
            [str(VENV_PYTHON), "run.py"],
            cwd=str(service_dir),
            env={**os.environ, "PYTHONUNBUFFERED": "1"}
        )
        return result.returncode == 0
    except KeyboardInterrupt:
        print(f"\n⏸️  Stopped {service_name}-backend")
        return True
    except Exception as e:
        print(f"❌ Error starting {service_name}-backend: {e}")
        return False

def start_all_services():
    """Start all services in parallel using subprocess."""
    print("\n" + "="*80)
    print("🚀 STARTING ALL BACKEND SERVICES (Unified Venv)")
    print("="*80)
    
    processes = {}
    
    for service_name, service in SERVICES.items():
        service_dir = service["dir"]
        if not service_dir.exists():
            print(f"❌ Service directory not found: {service_dir}")
            continue
        
        print(f"\n📍 Starting {service['description']} (port {service['port']})...")
        
        try:
            # Start service in background with shared venv
            proc = subprocess.Popen(
                [str(VENV_PYTHON), "run.py"],
                cwd=str(service_dir),
                env={**os.environ, "PYTHONUNBUFFERED": "1"}
            )
            processes[service_name] = proc
            print(f"   ✅ Process started (PID: {proc.pid})")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    if not processes:
        print("\n❌ No services started!")
        return False
    
    print("\n" + "="*80)
    print(f"✅ Started {len(processes)} service(s):")
    for service_name in processes:
        print(f"   • {SERVICES[service_name]['description']}")
    print("="*80)
    print("\n💡 Press Ctrl+C to stop all services")
    print("="*80 + "\n")
    
    # Wait for processes or keyboard interrupt
    try:
        while True:
            for service_name, proc in processes.items():
                if proc.poll() is not None:
                    print(f"⚠️  {service_name}-backend stopped (exit code: {proc.returncode})")
            import time
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\n" + "="*80)
        print("⏸️  STOPPING ALL SERVICES...")
        print("="*80)
        
        for service_name, proc in processes.items():
            try:
                proc.terminate()
                print(f"   ✅ Stopped {service_name}-backend")
            except Exception as e:
                print(f"   ❌ Error stopping {service_name}: {e}")
        
        print("="*80)
        print("✅ All services stopped")
        print("="*80 + "\n")
        return True

def main():
    """Main entry point."""
    # Check if venv exists
    if not VENV_PYTHON.exists():
        print("\n❌ ERROR: Root backend venv not found!")
        print(f"   Expected: {VENV_PYTHON}")
        print("\n   Create it with:")
        print("   cd backend")
        print("   python3.11 -m venv .venv")
        print("   ./.venv/bin/pip install -r requirements.txt")
        sys.exit(1)
    
    # Parse command line arguments
    if len(sys.argv) == 1 or (len(sys.argv) == 2 and sys.argv[1] == "--all"):
        # Start all services
        return start_all_services()
    elif len(sys.argv) == 3 and sys.argv[1] == "--service":
        # Start specific service
        service_name = sys.argv[2]
        return start_service(service_name)
    else:
        # Show help
        print(__doc__)
        print("Services available:")
        for name, service in SERVICES.items():
            print(f"  • {name:<12} {service['description']:<40} (port {service['port']})")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
