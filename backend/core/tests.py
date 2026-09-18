import tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from django.core import signing
from django.test import TestCase, override_settings
from .media import media_url


class MediaAndHealthTests(TestCase):
    def test_health_checks_database(self):
        self.assertEqual(self.client.get('/health/').status_code, 200)
        with patch('core.health.connection.cursor', side_effect=RuntimeError('database-secret')):
            response = self.client.get('/health/')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('database-secret', response.content.decode())

    def test_private_media_requires_valid_unexpired_path_bound_link(self):
        with tempfile.TemporaryDirectory() as directory, override_settings(MEDIA_ROOT=directory):
            Path(directory, 'resume.pdf').write_bytes(b'%PDF-test')
            url = media_url(None, SimpleNamespace(name='resume.pdf'))
            response = self.client.get(url)
            self.assertEqual(response.status_code, 200)
            response.close()
            self.assertEqual(self.client.get('/media/resume.pdf').status_code, 404)
            self.assertEqual(self.client.get(url.replace('resume.pdf?', 'other.pdf?')).status_code, 404)
            with patch('django.core.signing.time.time', return_value=1):
                expired = media_url(None, SimpleNamespace(name='resume.pdf'))
            self.assertEqual(self.client.get(expired).status_code, 404)

    def test_signed_traversal_is_rejected(self):
        token = signing.dumps('../manage.py', salt='prepmate.media')
        self.assertEqual(self.client.get('/media/../manage.py', {'token': token}).status_code, 404)
