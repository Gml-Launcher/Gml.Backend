![Frame 39262](https://github.com/user-attachments/assets/4ac0a227-a246-474a-8aab-1af34b6f8497)

# Gml.Backend

Gml.Backend is a comprehensive project designed to facilitate rapid deployment of server infrastructure for Minecraft game profiles, including Forge, Fabric, and LiteLoader. This product suite encompasses three integral services:

- **Gml.Web.Api**: A RESTful API that provides an interface for interaction with server data.
- **Gml.Web.Client**: Commonly referred to as the Monitoring Dashboard, this component offers a user-friendly interface for monitoring and administrating game profiles and the launcher.
- **Gml.Web.Skin.Service**: A service dedicated to the management of textures, allowing for customization and personalization for each player.

Together, these services offer a robust foundation for managing Minecraft game profiles with mods.

## Documentation
- [Official Website](https://gml.recloud.tech)
- [Official Documentation](https://wiki.recloud.tech)
- [Wiki Mirror](https://gml-launcher.github.io/Gml.Docs)

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
SECURITY_KEY=643866c80c46c909332b30600d3265803a3807286d6eb7c0d2e164877c809519

# Project settings
PROJECT_NAME=GmlBackendPanel
PROJECT_DESCRIPTION=
PROJECT_POLICYNAME=GmlServerPolicy
PROJECT_PATH=

# S3 Configuration
S3_ENABLED=true
MINIO_ROOT_USER=GamerVII
MINIO_ROOT_PASSWORD=waefawegferyjerthdrthrtrdthdr

# External Access Settings
MINIO_ADDRESS=:5009
MINIO_ADDRESS_PORT=5009
MINIO_CONSOLE_ADDRESS=:5010
MINIO_CONSOLE_ADDRESS_PORT=5010
PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_FILES=5005
PORT_GML_SKINS=5006

# Microservices
SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
```

### Step 4: Configure the Client `.env` File
Create or edit the `.env` file in the `src/Gml.Web.Client/` directory:

```plaintext
# Web API address
NEXT_PUBLIC_BACKEND_URL=http://localhost:5000/api/v1
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
