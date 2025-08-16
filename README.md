# Home Portal

---

# Purpose

I want to create a portal that allows me to easily access applications
related to or hosted in my home.

# High Level Design

An HTTP reverse proxy that routes requests to the appropriate application.

Separately to this project, I have registered domains for each application
in my local DNS resolver. The HTTP reverse proxy will inspect the request
and redirect the request to the appropriate application based on the domain.

Preferably, the HTTP reverse proxy will also have valid HTTPs certificates
and terminate the TLS connection.

# Technologies

Caddy