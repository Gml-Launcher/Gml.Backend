![image](https://github.com/GamerVII-NET/Gml.Backend/assets/111225722/3f09a2fb-74b1-4f9c-bf90-0e8d06970480)

# Gml Web API Setup and Configuration Guide

This guide will walk you through the necessary steps to clone, set up, and configure the Gml Web API.

## Setup

### Step 1: Cloning the Repository

Clone the repository by running the following command in your terminal:
Run the following command in your terminal:

```
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git
```

### Step 2: Navigating into the Project Directory

To navigate to the project directory, run the command below in your terminal:

```
cd Gml.Backend
```

### Step 3: Creation of the .env File

You need to create a .env file in src/Gml.Web.Client/ according to the template provided in
src/Gml.Web.Client/.env.example.

### Step 4: Running the Project Using Docker

Start the project by running the following command in your terminal:

```
docker compose up
```

Please ensure that Docker is installed and running on your computer. Once the project is running, you can access it in a
browser using the address provided by Docker.

## Detailed Settings

The appsettings.json configuration file is located in the src/Gml.Web.Api/src/Gml.Web.Api/ directory. Here is an example
configuration and a breakdown of what each field means:

```json 
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ServerSettings": {
    "ProjectName": "GmlServer1",
    "ProjectPath": "",
    "ProjectVersion": "1.0.0-alpha",
    "SkinDomains": ["recloud.tech", ".recloud.tech"],
    "ProjectDescription": "Gml (GamerVII Minecraft Launcher) is a cross-platform software infrastructure for creating and managing client-server Minecraft gaming systems.",
    "SecretKey": "SecretGmlKey1!@#&#^Tb786t^vb786hn8",
    "PolicyName": "GmlPolicy"
  },
  "ConnectionStrings": {
    "SQLite": "Data Source=data.db"
  }
}
```

### Logging

• Defines how system events are logged. </br>
• **LogLevel:** Specifies logging level based on the namespace of the logged item. </br>
• **Default:** Default level for all log items. </br>
• **Microsoft.AspNetCore:** Specific logging level for items from the Microsoft.AspNetCore namespace. </br>

### ServerSettings

• **Basic server** settings. </br>
• **ProjectName:** The name of your project. </br>
• **ProjectPath:** The path where the project is located. </br>
• **ProjectVersion:** The version of your project. </br>
• **SkinDomains:** Domains from which the server will serve requested skins. </br>
• **ProjectDescription:** The description of your project. </br>
• **SecretKey:** Secret key used for authentication. </br>

• **PolicyName:** Policy name for authorisation.

### ConnectionStrings

Database connection strings. </br>

• **SQLite:** SQLite database connection string. </br>

**Important:** Always keep your SecretKey and SQLite connection string confidential.
