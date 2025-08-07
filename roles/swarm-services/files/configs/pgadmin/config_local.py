import os

# Abilitare OpenID Connect
AUTHENTICATION_SOURCES = ["oauth2"]

clientId = os.path.expandvars('$PGADMIN_OIDC_CLIENT_ID')
clientSecret = os.path.expandvars('$PGADMIN_OIDC_CLIENT_SECRET')
OAUTH2_CONFIG = [
    {
        'OAUTH2_NAME': 'oidc',
        'OAUTH2_DISPLAY_NAME': 'OpenID Connect',
        'OAUTH2_CLIENT_ID': clientId,
        'OAUTH2_CLIENT_SECRET': clientSecret,
        'OAUTH2_TOKEN_URL': 'https://auth.vcc.internal/token',
        'OAUTH2_AUTHORIZATION_URL': 'https://auth.vcc.internal/auth',
        'OAUTH2_API_BASE_URL': 'https://auth.vcc.internal',
        'OAUTH2_SERVER_METADATA_URL': 'https://auth.vcc.internal/.well-known/openid-configuration',
        'OAUTH2_USERINFO_ENDPOINT': 'https://auth.vcc.internal/userinfo',
        'OAUTH2_SCOPE': 'openid email profile groups offline_access',
        'OAUTH2_ICON': 'fa-lock',
        'OAUTH2_BUTTON_COLOR': '#000000',
        'OAUTH2_SSL_CERT_VERIFICATION': False,
        'OAUTH2_AUTO_LOGIN': True
    }
]