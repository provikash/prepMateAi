#!/usr/bin/env python
"""
Quick test script to debug registration issues.
Run: python test_register.py
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(__file__))

django.setup()

from django.contrib.auth import get_user_model
from users.serializers import RegisterSerializer
from users.services import AuthService

User = get_user_model()

def test_registration():
    """Test the registration flow step by step."""
    
    test_data = {
        "email": "test@example.com",
        "name": "Test User",
        "password": "TestPassword123!",
        "password_confirm": "TestPassword123!",
    }
    
    print("=" * 60)
    print("TESTING REGISTRATION FLOW")
    print("=" * 60)
    
    # Test 1: Validate serializer
    print("\n1. Testing Serializer Validation...")
    try:
        serializer = RegisterSerializer(data=test_data)
        if serializer.is_valid():
            print("✓ Serializer is valid")
        else:
            print(f"✗ Serializer errors: {serializer.errors}")
            return
    except Exception as e:
        print(f"✗ Serializer validation error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Test 2: Create user
    print("\n2. Testing User Creation...")
    try:
        user = serializer.save()
        print(f"✓ User created: {user.email} (ID: {user.id})")
    except Exception as e:
        print(f"✗ User creation error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Test 3: Check UserProfile was created
    print("\n3. Checking UserProfile...")
    try:
        profile = user.profile
        print(f"✓ UserProfile exists: {profile.id}")
    except Exception as e:
        print(f"✗ UserProfile error: {e}")
        import traceback
        traceback.print_exc()
    
    # Test 4: Generate tokens
    print("\n4. Testing Token Generation...")
    try:
        tokens = AuthService.issue_tokens(user)
        print(f"✓ Tokens generated:")
        print(f"  - Access token length: {len(tokens.get('access', ''))}")
        print(f"  - Refresh token length: {len(tokens.get('refresh', ''))}")
    except Exception as e:
        print(f"✗ Token generation error: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # Cleanup
    print("\n5. Cleaning up test user...")
    try:
        user.delete()
        print("✓ Test user deleted")
    except Exception as e:
        print(f"⚠ Could not delete test user: {e}")
    
    print("\n" + "=" * 60)
    print("REGISTRATION TEST COMPLETED SUCCESSFULLY!")
    print("=" * 60)

if __name__ == "__main__":
    test_registration()
