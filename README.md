1. First, download the image:
    ```
    docker pull ghcr.io/gamervii-net/gml-web-api:master
    ```

2. Check that the image has been downloaded:
    ```
    docker images
    ```

3. Configure the image:
    ```
    docker exec -it CONTAINER_ID bash
    ```

4. Run the service:
    ```
    docker run -p 5000:8080 ghcr.io/gamervii-net/gml-web-api:master
    ```

5. Confirm that the server is running:
    ```
    info: Microsoft.Hosting.Lifetime[14]
          Now listening on: http://[::]:8080
    ...
    ```

6. Enter the Docker OS, replacing CONTAINER_ID in the command:
    ```
    docker exec -it CONTAINER_ID bash
    ```

7. Install the necessary components:
    ```
    apt-get update && apt-get install wget unzip curl nano -y
    ```

8. Change the project name:
    ```
    nano /app/appsettings.json
    ```
    Press CTRL+X, then Y, and Enter.

9. Restart the Docker container:
    ```
    docker restart CONTAINER_ID
    ```

# Installing the client from an external file

1. Create a profile.

2. Enter the Docker OS, replacing CONTAINER_ID in the command:
    ```
    docker exec -it CONTAINER_ID bash
    cd /root/PROJECT_NAME/clients/
    wget LINK_TO_ZIP_FILE
    unzip Client.zip
    rm -Rf Client.zip
    ```
