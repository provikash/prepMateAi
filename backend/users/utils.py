import random
from django.core.mail import send_mail
from django.conf import settings
from .models import OTP
def generate_otp():
  return str(random.randint(100000,999999))

def send_otp_email(email,otp):
  subject='your OTP Verification Code'
  message =f"""
  Hello,
  Your OTP verification code is:{otp}
  This OTP is valid for 5 minutes.

  Thanks
  PrepMateAi
  """
  send_mail(subject,message,settings.EMAIL_HOST_USER,[email],fail_silently=False)

def resend_otp(email,purpose):
  """Delete old OTP and sends a new one """
  OTP.objects.filter(email=email,purpose=purpose).delete()
otp_code = generate_otp()
OTP.objects.create(email=email,otp=otp_code)
send_otp_email(email,otp_code)