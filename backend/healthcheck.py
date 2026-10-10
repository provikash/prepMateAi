import os
import urllib.request

host = os.environ['ALLOWED_HOSTS'].split(',')[0].strip()
request = urllib.request.Request(f"http://127.0.0.1:{os.getenv('PORT', '8000')}/health/", headers={'Host': host})
with urllib.request.urlopen(request, timeout=4) as response:
    if response.status != 200:
        raise SystemExit(1)
