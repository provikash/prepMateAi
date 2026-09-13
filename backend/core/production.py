import os
os.environ["DJANGO_ENV"] = "production"
from .settings import *  # noqa: F403
