"""Short-lived file links for private resume documents and profile images."""
from pathlib import Path
from urllib.parse import quote, urlencode

from django.conf import settings
from django.core import signing
from django.http import FileResponse, Http404
from django.views.decorators.http import require_GET


def media_url(request, file_field):
    if not file_field:
        return None
    name = file_field.name
    token = signing.dumps(name, salt='prepmate.media')
    url = '/media/' + quote(name, safe='/') + '?' + urlencode({'token': token})
    return request.build_absolute_uri(url) if request else url


@require_GET
def serve_media(request, path):
    try:
        name = signing.loads(request.GET.get('token', ''), salt='prepmate.media', max_age=3600)
        if name != path:
            raise Http404
        root = Path(settings.MEDIA_ROOT).resolve()
        target = (root / path).resolve()
        if not target.is_relative_to(root) or not target.is_file():
            raise Http404
    except (signing.BadSignature, ValueError, OSError):
        raise Http404 from None
    response = FileResponse(target.open('rb'))
    response['Cache-Control'] = 'private, max-age=300'
    response['X-Content-Type-Options'] = 'nosniff'
    return response
