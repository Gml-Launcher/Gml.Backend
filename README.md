![Frame 39262](https://github.com/user-attachments/assets/4ac0a227-a246-474a-8aab-1af34b6f8497)

**Switch language:** [Русский](README.ru.md)

# Gml.Backend

Gml.Backend is a comprehensive project designed to facilitate rapid deployment of server infrastructure for Minecraft game profiles, including Forge, Fabric, and LiteLoader. This product suite encompasses three integral services:

- **Gml.Web.Api**: A RESTful API that provides an interface for interaction with server data.
- **Gml.Web.Client**: Commonly referred to as the Monitoring Dashboard, this component offers a user-friendly interface for monitoring and administrating game profiles and the launcher.
- **Gml.Web.Skin.Service**: A service dedicated to the management of textures, allowing for customization and personalization for each player.

Together, these services offer a robust foundation for managing Minecraft game profiles with mods.

## Documentation

- [Official Website](https://gml-launcher.ru)
- [Official Documentation](https://gml-launcher.ru/docs/welcome)

## Quick Install With Gml Manager

The easiest way to start the installation manager:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh
```

Gml Manager will ask for the language, action, installation directory, version, and proxy mode interactively. The language prompt defaults to the system locale, the version prompt defaults to the latest stable GitHub tag, and the default installation directory is `/srv/gml`.

Two proxy modes are available:

- `external` — GML uses HTTP on `PORT_GML_FRONTEND` behind an existing nginx or another reverse proxy;
- `global` — Angie binds public ports 80/443 and automatically obtains a Let’s Encrypt certificate for `GML_PROXY_DOMAIN`.

Before enabling `global`, the manager verifies that ports 80/443 are free, the DNS A record points to the server's public IPv4, and any existing AAAA record points to its public IPv6. DNS proxying through Cloudflare/CDNs is not supported in this mode.

If you are already running as `root`, you can use `sh` without `sudo`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sh
```

For a non-interactive installation, pass arguments through `sh -s --`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --dir /srv/gml
```

To install Angie as the primary HTTPS proxy non-interactively:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --dir /srv/gml --proxy-mode global --domain gml.example.com --accept-acme-terms
```

The same options can be passed to `update` to switch between `external` and `global`. If `--proxy-mode` is omitted during an update, the current mode is preserved.

The minimum supported version for a new installation is `v2026.2`; the limit does not apply to updates.

Pass `--version` only when you want to pin a specific Docker image tag:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --version v2026.2 --dir /srv/gml
```

Use these commands to update or remove the installation:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- update --dir /srv/gml
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- delete --dir /srv/gml
```

## Local Development and Rider

Install .NET SDK 10, the .NET/ASP.NET Core 8 runtime for the skin service, Node.js 20+,
and npm. Prepare the submodules and dependencies from the repository root:

```bash
git submodule update --init --recursive
npm --prefix src/Gml.Web.Client ci
dotnet restore Gml.Backend.sln
```

On the first Development launch, the API generates a random key in
`src/Gml.Web.Api/src/Gml.Web.Api/database/development.key` and reuses it for subsequent
Rider and script launches. The file is excluded from Git. The `SECURITY_KEY` environment
variable takes precedence; supply it through the environment in production.

Open `Gml.Backend.sln` in Rider and Run or Debug the shared **GML Development**
configuration. It starts Frontend, Backend (development), and Skins (development)
together; Debug attaches to both .NET services. The .NET working directories are
their respective project directories. Use Stop All to stop the compound configuration.

For a terminal launch on Linux/macOS:

```bash
./scripts/dev.sh
```

The script also works from another directory when invoked by its absolute path.
It checks tools, dependencies, and ports, and stops its process groups on Ctrl+C,
SIGTERM, or any service exit. SQLite and service files use the usual local development directories.

Open **http://localhost:3000**. Next.js forwards `/api*`, `/swagger*`, `/ws*`, and exact
`/health` requests to `http://127.0.0.1:5002`. `/skins` and `/skins/*` go to port 5086,
with the `/skins` prefix removed. Browser API and WebSocket requests use the frontend origin.
The API's HTTP `frontend` launch profile uses the public marketplace at
`https://gml-market.recloud.tech`; skins use the `http` profile. No local marketplace is required.

Like Angie, an unfinished installation redirects `/` to `/mnt`; completed installations
redirect `/mnt` and its nested pages to `/`. If the API is unavailable or the setup check
takes more than three seconds, the root stays reachable and `/mnt` redirects to `/`.

For a separately launched frontend, override `DEV_BACKEND_URL` and `DEV_SKINS_URL` in
`src/Gml.Web.Client/.env.development.local`. Defaults are `http://127.0.0.1:5002` and
`http://127.0.0.1:5086`.

## Installation Instructions

### Step 1: Clone the Repository

Clone the stable version of the repository using the following command:

```bash
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git
```

### Step 2: Navigate to the Project Directory

Move to the project directory:

```bash
cd Gml.Backend
```

### Step 3: Configure the `.env` File

Create or edit the `.env` file in the root of the `Gml.Backend` directory. Below is an example configuration:

```plaintext
# User and Group Identifiers for Linux
UID=0
GID=0

# Security key (replace with your own secure key)
SECURITY_KEY=<your-security-key>

# Project settings
PROJECT_NAME=GmlBackendPanel
PROJECT_DESCRIPTION=
PROJECT_POLICYNAME=GmlServerPolicy
PROJECT_PATH=

# External Access Settings
PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_SKINS=5006

# Microservices
SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech
```

### Step 4: Configure the Client `.env` File

Create or edit the `.env` file in the `src/Gml.Web.Client/` directory:

```plaintext
# Web API address
NEXT_PUBLIC_BACKEND_URL=http://localhost:5000/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
```

### Step 5: Launch the Project with Docker

Ensure Docker is installed and running on your system. Then, execute the following command to build and start the project:

```bash
docker compose up -d --build
```

Docker will download the necessary images and launch the project. Once the containers are running, you can access the services in your browser at the following addresses:

## Infrastructure

> **Note**: Starting from version `0.1.0-rc1`, server files are stored in the installation directory. [Learn more](#).

### Server Infrastructure

- **Web API**: `http://localhost:5000` (Main service)
- **Web Dashboard**: `http://localhost:5003` (Requires registration)
- **Gml.Web.Skin.Service**: `http://localhost:5006` (Accessible only within the container)

## Important Notes

- **FileBrowser** has been removed starting from version `0.1.0-rc1`. [Details](#).
- **Minio** has been removed starting from version `1.0.3`. [Details](#).
- Ensure the `.env` files are correctly configured before launching the project. Update the configurations as needed based on your requirements.
