# Public read-only demo

Runs the [everything stack](../README.md) on a public server with a
read-only login, so people can click around Rampart before installing it.

What this overlay changes:

- **Caddy** is the only published service (ports 80/443). It gets the HTTPS
  certificate automatically and answers `403` to every non-GET request except
  sign-in/out and Rampart's own RUM beacon. Even someone holding the admin
  password can't change anything through it.
- A **readonly user** is created for visitors (`viewer@rampart.local` /
  `rampart-demo` by default).
- A **traffic** container drives the demo app the way its browser page does,
  so traces, logs, errors and detection findings keep flowing with nobody
  watching.
- `reset.sh` wipes everything and re-provisions from the latest image. Run it
  nightly.

## Free hosting (Oracle Cloud Always Free)

1. Create an Oracle Cloud account (they verify with a card; Always Free
   resources are not charged). Create an **Ampere A1** instance with 4 OCPU /
   24 GB, Ubuntu 24.04. Under Networking → IP Administration, reserve a
   **static public IP** and attach it.
2. In the instance's VCN security list, allow ingress TCP **80** and **443**
   from `0.0.0.0/0`. Oracle's Ubuntu image also has iptables rules; open
   the same ports there:

   ```bash
   sudo iptables -I INPUT 6 -p tcp -m multiport --dports 80,443 -j ACCEPT
   sudo netfilter-persistent save
   ```

3. Point a name at the IP: an `A` record for a subdomain you own
   (e.g. `rampart-demo.example.com`), or skip DNS and use
   `demo.<ip-with-dashes>.sslip.io` (for example
   `demo.203-0-113-7.sslip.io`).
4. On the instance: install Docker (`curl -fsSL https://get.docker.com | sh`),
   then:

   ```bash
   git clone https://github.com/penpalabs/rampart.git
   cd rampart/examples/everything
   cat > demo/.env <<EOF
   DEMO_DOMAIN=rampart-demo.example.com
   RAMPART_ADMIN_PASSWORD=$(openssl rand -base64 24)
   EOF
   sudo demo/reset.sh
   ```

   The first run builds the local images (the remote agent compiles from
   source), so allow 15-20 minutes. Later runs reuse the build cache.
5. Reset nightly:

   ```bash
   echo "0 4 * * * root $PWD/demo/reset.sh >> /var/log/rampart-demo.log 2>&1" | sudo tee /etc/cron.d/rampart-demo
   ```

Optional `demo/.env` settings: `DEMO_USER_EMAIL` and `DEMO_USER_PASSWORD`
override the visitor login (the password needs 10+ characters and must not
contain the email's name).

## Notes

- Keep `demo/.env` private; it holds the admin password. It is git-ignored.
- Certificates live in `demo/caddy-data/`, outside the volumes that `down -v`
  removes, so resets don't request new ones.
- The `heavy` profile (MySQL, MSSQL, Cassandra, ...) stays off. Some of those
  images have no ARM build, and the free VM doesn't need them.
- No rate limiting. Writes are already refused at the proxy; add Caddy's
  rate-limit plugin if the demo ever attracts abuse.
