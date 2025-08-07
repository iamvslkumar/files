import ssl
import socket
from tabulate import tabulate

URLS = [
    "google.com",
    "github.com",
    "example.com",
    "stackoverflow.com"
]

def get_certificate_info(hostname):
    port = 443
    ctx = ssl.create_default_context()
    try:
        with ctx.wrap_socket(socket.socket(), server_hostname=hostname) as s:
            s.settimeout(5)
            s.connect((hostname, port))
            cert = s.getpeercert()
            issuer = dict(x[0] for x in cert.get('issuer', []))
            subject = dict(x[0] for x in cert.get('subject', []))
            return {
                "Hostname": hostname,
                "Issuer CN": issuer.get('commonName', ''),
                "Issuer O": issuer.get('organizationName', ''),
                "Subject CN": subject.get('commonName', ''),
                "Valid From": cert.get('notBefore', ''),
                "Valid To": cert.get('notAfter', ''),
                "Serial Number": cert.get('serialNumber', '')
            }
    except Exception as e:
        return {
            "Hostname": hostname,
            "Issuer CN": "ERROR",
            "Issuer O": str(e),
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
