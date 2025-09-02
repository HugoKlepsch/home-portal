# Home Portal

---

# Purpose

I want to create a portal that allows me to easily access applications
related to or hosted in my home.

# High Level Design

An HTTP reverse proxy that routes requests to the appropriate application.

Separately to this project, I have registered domains for each application
in my local DNS resolver. The HTTP reverse proxy will inspect the domain
of the request and redirect it to the appropriate application.

Preferably, the HTTP reverse proxy will also have valid HTTPs certificates
and terminate the TLS connection.

# Technologies

* [Docker Compose](https://docs.docker.com/compose/)
* [Caddy](https://github.com/caddyserver/caddy)
  * Uses: [Caddy Linode DNS Plugin](https://github.com/HugoKlepsch/caddy-dns_linode)
    * Uses: [LibDNS Linode](https://github.com/HugoKlepsch/libdns-linode)

# TLS Certificates

Caddy automatically sets up TLS certificates from Let's Encrypt using HTTP or 
DNS-01 challenges. Since these domains only exist in my local DNS resolver,
I can't use the HTTP-01 challenge, because it would require serving the challenge
response publicly from the HTTP reverse proxy.

DNS-01 however, will work fine. The `dns.providers.linode` plugin is used by 
Caddy to edit DNS records in my Linode account. The source for this plugin is
available [here](https://github.com/HugoKlepsch/caddy-dns_linode). This 
repository serves as an example of how to use the plugin.

# Usage

The [Dockerfile](https://github.com/HugoKlepsch/home-portal/blob/0ffd20df86124c927c71a2b26e44ad0fdf0337d6/Dockerfile) 
builds caddy with the plugin. It takes in the version of Caddy and the plugin 
source as arguments, supplied by the [docker-compose file](https://github.com/HugoKlepsch/home-portal/blob/973d9ed595e9507c6de7d5f8b860b5d338a36643/compose/docker-compose.yml#L6-L8).

There are some secrets that need to be stored in environment variables. 
These are stored in a `.env.bash` file. A template for this file is found at
[`.env.bash.template`](https://github.com/HugoKlepsch/home-portal/blob/011a476e1e387edf07d1db747ca57e79661b8a6c/.env.bash.template).
Copy this file to `.env.bash` and fill in the secrets.
See [the README in the libdns-linode package](https://github.com/HugoKlepsch/libdns-linode?tab=readme-ov-file#getting-a-token)
for instructions on how to get a Linode Personal Access Token.

## Building

First, set up environment variables from `.env.bash`:

```bash
source .env.bash
```

Then, build the image with the Linode plugin:

```bash
docker compose -f compose/docker-compose.yml build
```

Now you can run the image:

```bash
docker compose -f compose/docker-compose.yml up -d
```

## Config examples

To use this module for the ACME DNS challenge, [configure the ACME issuer in your Caddy JSON](https://caddyserver.com/docs/json/apps/tls/automation/policies/issuer/acme/) like so:

```json
{
	"module": "acme",
	"challenges": {
		"dns": {
			"provider": {
				"name": "linode",
				"api_token": "{env.LINODE_PERSONAL_ACCESS_TOKEN}",
				"api_url": "{env.LINODE_API_URL}",
				"api_version": "{env.LINODE_API_VERSION}", 
				"debug_logs_enabled": false
			}
		}
	}
}
```

or with the Caddyfile...

...globally:

```Caddyfile
# globally
{
	acme_dns linode {$LINODE_PERSONAL_ACCESS_TOKEN}
}
```

...or globally and with optional fields:

```Caddyfile

# globally, with optional fields
{
	acme_dns linode {
	  api_token {$LINODE_PERSONAL_ACCESS_TOKEN}
	  api_url {$LINODE_API_URL}
	  api_version {$LINODE_API_VERSION}
	}
}
example.com {
}
```

...or per site:

```Caddyfile
# one site
example.com {
	tls {
		dns linode {$LINODE_PERSONAL_ACCESS_TOKEN}
	}
}
```

```Caddyfile
# one site, with optional fields
example.com {
	tls {
		dns linode {
		  api_token {$LINODE_PERSONAL_ACCESS_TOKEN}
		  api_url {$LINODE_API_URL}
		  api_version {$LINODE_API_VERSION}
		  debug_logs_enabled false
		}
	}
}
```

Full example:

```Caddyfile

# Full example, with recommended settings for Linode
example.com {

    tls {
	    ca https://acme-v02.api.letsencrypt.org/directory

        dns linode {
            api_token {$LINODE_DNS_PAT}
            api_url {$LINODE_API_URL}
            api_version {$LINODE_API_VERSION}
            debug_logs_enabled false
        }
        # Delay to ensure that the record is propagated, but disable
        # checks because the local check always fails for me. Could be related
        # to fail-loop described below?
        propagation_delay 2m
        propagation_timeout -1 # no checks
        # When creating a TXT record with "0" TTL, Linode considers this a
        # request for a record with the "Default" TTL, which results in a zone
        # file with no TTL value.
        # Common resolvers like 1.1.1.1 and 8.8.8.8 seem to cache this for a
        # very long time. (24h?)
        # Set dns_ttl to the lowest value allowed by Linode to avoid fail-loops
        # where the CA sees the old TXT record despite the new one being present.
        dns_ttl 30s
        resolvers 1.1.1.1
    }

	# Serve static text at root
	respond / "Hello world!"
}
```

You can replace `{$*}` or `{env.*}` with the actual values if you prefer to put it directly in your config instead of an environment variable.

The fields are:

- `api_token` - The Linode Personal Access Token to use.
- `api_url` - The Linode API hostname to use, i.e. `api.linode.com`.
- `api_version` - The Linode API version to use, i.e. `v4`.
- `debug_logs_enabled` - true|false, whether to enable debug logs.
