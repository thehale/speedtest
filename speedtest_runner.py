#!/usr/bin/env python3
import subprocess
import json
import csv
import os
from datetime import datetime

DATA_FILE = os.environ.get('DATA_FILE', '/data/speedtest.csv')

def run_speedtest():
    """Run Ookla speedtest and return results"""
    try:
        result = subprocess.run(
            ['speedtest', '--format=json', '--accept-license', '--accept-gdpr'],
            capture_output=True,
            text=True,
            timeout=120
        )
        
        if result.returncode != 0:
            print(f"Speedtest failed: {result.stderr}")
            return None
        
        data = json.loads(result.stdout)
        
        # Extract relevant data
        timestamp = datetime.now().isoformat()
        download_mbps = data['download']['bandwidth'] * 8 / 1_000_000  # Convert bytes/s to Mbps
        upload_mbps = data['upload']['bandwidth'] * 8 / 1_000_000
        ping_ms = data['ping']['latency']
        jitter_ms = data['ping'].get('jitter', 0)
        server_name = data['server']['name']
        server_location = data['server']['location']
        
        return {
            'timestamp': timestamp,
            'download_mbps': round(download_mbps, 2),
            'upload_mbps': round(upload_mbps, 2),
            'ping_ms': round(ping_ms, 2),
            'jitter_ms': round(jitter_ms, 2),
            'server_name': server_name,
            'server_location': server_location
        }
    except Exception as e:
        print(f"Error running speedtest: {e}")
        return None

def save_result(result):
    """Save result to CSV file"""
    if result is None:
        return
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    
    # Check if file exists to determine if we need headers
    file_exists = os.path.isfile(DATA_FILE)
    
    with open(DATA_FILE, 'a', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['timestamp', 'download_mbps', 'upload_mbps', 'ping_ms', 'jitter_ms', 'server_name', 'server_location'])
        
        if not file_exists:
            writer.writeheader()
        
        writer.writerow(result)
    
    print(f"Saved speedtest result at {result['timestamp']}")

if __name__ == '__main__':
    result = run_speedtest()
    save_result(result)
