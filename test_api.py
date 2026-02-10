import requests
import json

BASE_URL = "http://0.0.0.0:5000/api/auth"

def test_endpoint(path, method="GET", data=None):
    url = f"{BASE_URL}/{path}"
    print(f"Testing {method} {url}...")
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")
    print("-" * 30)

if __name__ == "__main__":
    # Test Registration
    test_endpoint("register/", "POST", {
        "username": "testuser",
        "email": "test@example.com",
        "password": "password123"
    })
    
    # Test Login
    test_endpoint("login/", "POST", {
        "username": "testuser",
        "password": "password123"
    })
    
    # Test other endpoints (placeholders)
    test_endpoint("verify-otp/", "POST", {"email": "test@example.com", "otp": "123456"})
    test_endpoint("forget-password/", "POST", {"email": "test@example.com"})
    test_endpoint("reset-password/", "POST", {"email": "test@example.com", "otp": "123456", "new_password": "newpassword123"})
