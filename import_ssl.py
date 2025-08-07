import ssl
import socket
from urllib.parse import urlparse
from tabulate import tabulate

URLS = [
    "https://github.com:443",
    "https://azure.microsoft.com:443",
    "https://example.com:443",
    "https://stackoverflow.com:443",
    "https://expired.badssl.com:443",  # Should give an error
    # Add more as needed
]

def get_certificate_info(full_url):
    parsed = urlparse(full_url)
    if parsed.scheme != "https":
        return {
            "URL": full_url,
            "Hostname": "",
            "Port": "",
            "Issuer CN": "NOT HTTPS",
            "Issuer O": "",
            "Is DigiCert": "N/A",
            "Subject CN": "",
            "Valid From": "",
            "Valid To": "",
            "Serial Number": ""
        }
    hostname = parsed.hostname
    port = parsed.port if parsed.port else 443

    ctx = ssl.create_default_context()
    try:
        with ctx.wrap_socket(socket.socket(), server_hostname=hostname) as s:
            s.settimeout(5)
            s.connect((hostname, port))
            cert = s.getpeercert()
            issuer = dict(x[0] for x in cert.get('issuer', []))
            subject = dict(x[0] for x in cert.get('subject', []))
            issuer_org = issuer.get('organizationName', '')
            is_digicert = "Yes" if issuer_org and "DigiCert Inc" in issuer_org else "No"
            return {
                "URL": full_url,
                "Hostname": hostname,
                "Port": port,
                "Issuer CN": issuer.get('commonName', ''),
                "Issuer O": issuer_org,
                "Is DigiCert": is_digicert,
                "Subject CN": subject.get('commonName', ''),
                "Valid From": cert.get('notBefore', ''),
                "Valid To": cert.get('notAfter', ''),
                "Serial Number": cert.get('serialNumber', '')
            }
    except Exception as e:
        return {
            "URL": full_url,
            "Hostname": hostname,
            "Port": port,
            "Issuer CN": "ERROR",
            "Issuer O": str(e),
            "Is DigiCert": "ERROR",
            "Subject CN": "",
            "Valid From": "",
            "Valid To": "",
            "Serial Number": ""
        }

results = []
for url in URLS:
    details = get_certificate_info(url)
    results.append(details)

print(tabulate(results, headers="keys", tablefmt="grid"))
