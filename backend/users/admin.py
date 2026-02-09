from django.contrib import admin 
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User,OTP

class UserAdmin(BaseUserAdmin):
  ordering =('email')
  list_display=('email',
               'is_active',
               'is_verified',
               'is_staff',
               'is_superuser',
               'date_joined',)
  list_filter =('is_active',
               'is_verified',
                'is_staff',
               'is_superuser',
               )
  search_fields =('email',)
  fieldsets=(None,{'field':('email','password')}
         ),('Permissions',{'fields':('is_active','is_verified','is_staff','is_superuser','groups','user_permissions')}),('Dates',{'fields':('last_login','date_joined')},)

add_fieldsets=((None,{'classes':('wide',),'fields':('email','password1','password2','is_active','is_staff','super_user')}),)

filter_horizontal=('groups','user_permissions',)

class OTPAdmin(admin.ModelAdmin):
  list_display = ('email','otp','purpose','created_at')
  search_fields =('email')