# Subspace - A simple WireGuard VPN server GUI

![Screenshot](https://raw.githubusercontent.com/simwood/subspace/master/screenshot1.png?cachebust=8923409243)

## Screenshots

[Screenshot 1](https://raw.githubusercontent.com/simwood/subspace/master/screenshot1.png)

[Screenshot 2](https://raw.githubusercontent.com/simwood/subspace/master/screenshot2.png)

[Screenshot 3](https://raw.githubusercontent.com/simwood/subspace/master/screenshot3.png)

[Screenshot 4](https://raw.githubusercontent.com/simwood/subspace/master/screenshot4.png)

## Changes from original

This has been forked by [Simwood](https://simwood.com) as the original didn't appear to be maintained. There are a number of changes:

* Replace CloudFlare DNS with Quad9 to enhance privacy
* Disable Let's Encrypt as the library was outdated and it didn't work. Ensure the web interface is not publicly reachable!
* Remove 10 user limit
* Rebuild Docker image and add to Dockerhub

## Features

* **WireGuard VPN Protocol**
  * The most modern and fastest VPN protocol.
* **Single Sign-On (SSO) with SAML**
  * Support for SAML providers like G Suite and Okta.
* **Add Devices**
  * Connect from Mac OS X, Windows, Linux, Android, or iOS.
* **Remove Devices**
  * Removes client key and disconnects client.
* **Auto-generated Configs**
  * Each client gets a unique downloadable config file.
  * Generates a QR code for easy importing on iOS and Android.

## Run Subspace on a VPS

Running Subspace on a VPS is designed to be as simple as possible.

  * Public Docker image.
  * Single static Go binary with assets bundled.
  * Automatic TLS using Let's Encrypt.
  * Redirects http to https.
  * Works with a reverse proxy or standalone.

### 1. Get a server

**Recommended Specs**

* Type: VPS or dedicated
* Distribution: Ubuntu 16.04 (Xenial)
* Memory: 512MB or greater

### 2. Add a DNS record

Create an internal DNS `A` record in your domain pointing to your server's management IP address.

**Example:** `subspace.example.com  A  172.16.1.1`

Create a public DNS `A` record in your domain pointing to your server's WireGuard address.

**Requirements**

* Your server must have a publicly resolvable DNS record.
* Your server must be reachable over the internet 51820/udp (WireGuard).
* Your server should not be reachable over the internet on ports 80/tcp or 443/tcp.

### Usage

**Example usage:**

```bash
$ subspace --http-host subspace.example.com
```
### Usage

```bash
  -backlink string
        backlink (optional)
  -datadir string
        data dir (default "/data")
  -debug
        debug mode
  -help
        display help and exit
  -http-addr string
        HTTP listen address (default ":80")
  -http-host string
        HTTP host
  -http-insecure
        enable sessions cookies for http (no https) not recommended
  -letsencrypt
        enable TLS using Let's Encrypt on port 443 (default true)
  -version
        display version and exit
```
### Run as a Docker container

![Docker Image Version (latest by date)](https://img.shields.io/docker/v/simwood/subspace?sort=date)
![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/simwood/subspace)
![Docker Stars](https://img.shields.io/docker/stars/simwood/subspace)

#### Install WireGuard on the host

The container expects WireGuard to be installed on the host. The official image is `simwood/subspace`.

```bash
add-apt-repository -y ppa:wireguard/wireguard
apt-get update
apt-get install -y wireguard

# Remove dnsmasq because it will run inside the container.
apt-get remove -y dnsmasq

# Set DNS server.
echo nameserver 9.9.9.9 >/etc/resolv.conf

# Load modules.
modprobe wireguard
modprobe iptable_nat
modprobe ip6table_nat

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

```

Follow the official Docker install instructions: [Get Docker CE for Ubuntu](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)

Make sure to change the `--env SUBSPACE_HTTP_HOST` to your publicly accessible domain name.

```bash

# Your data directory should be bind-mounted as `/data` inside the container using the `--volume` flag.
$ mkdir /data

docker create \
    --name subspace \
    --restart always \
    --network host \
    --cap-add NET_ADMIN \
    --volume /usr/bin/wg:/usr/bin/wg \
    --volume /data:/data \
    --env SUBSPACE_HTTP_HOST=subspace.example.com \
    --env SUBSPACE_HTTP_INSECURE=true \
    -env SUBSPACE_LETSENCRYPT=false \
    simwood/subspace:latest

$ sudo docker start subspace

$ sudo docker logs subspace

<log output>

```

#### Updating the container image

Pull the latest image, remove the container, and re-create the container as explained above.

```bash
# Pull a specific version
$ sudo docker pull simwood/subspace:1.0

# Or the latest image
$ sudo docker pull simwood/subspace:latest

# Stop the container
$ sudo docker stop subspace

# Remove the container (data is stored on the mounted volume)
$ sudo docker rm subspace

# Re-create and start the container
$ sudo docker create ... (see above)
```
