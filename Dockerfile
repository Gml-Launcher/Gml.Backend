FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
RUN apt-get update && apt-get install -y git
COPY ["src/Gml.Web.Api/Gml.Web.Api.csproj", "src/Gml.Web.Api/"]
COPY ["src/Gml.Web.Api.Domains/Gml.Web.Api.Domains.csproj", "src/Gml.Web.Api.Domains/"]
COPY ["src/Gml.Web.Api.Dto/Gml.Web.Api.Dto.csproj", "src/Gml.Web.Api.Dto/"]
COPY ["src/Gml.Web.Api.EndpointSDK/Gml.Web.Api.EndpointSDK.csproj", "src/Gml.Web.Api.EndpointSDK/"]
COPY ["src/Gml.Core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge.csproj", "src/Gml.Core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/"]
RUN dotnet restore "src/Gml.Web.Api/Gml.Web.Api.csproj"
COPY . .
WORKDIR "/src/src/Gml.Web.Api"
RUN dotnet build "Gml.Web.Api.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Gml.Web.Api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Java installation stage
FROM adoptopenjdk:11-jdk AS java

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Gml.Web.Api.dll"]
