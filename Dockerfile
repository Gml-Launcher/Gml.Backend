FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/Gml.Web.Api/src/Gml.Web.Api/Gml.Web.Api.csproj", "src/Gml.Web.Api/src/Gml.Web.Api/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/Gml.Common/Gml.Common/Gml.Common.csproj", "src/Gml.Web.Api/src/Gml.Core/src/Gml.Common/Gml.Common/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/Gml.Core.Interfaces/Gml.Core.Interfaces.csproj", "src/Gml.Web.Api/src/Gml.Core/src/Gml.Core.Interfaces/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/Gml.Core/Gml.Core.csproj", "src/Gml.Web.Api/src/Gml.Core/src/Gml.Core/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge.csproj", "src/Gml.Web.Api/src/Gml.Core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/CmlLib.ExtendedCore/src/CmlLib.Core.csproj", "src/Gml.Web.Api/src/Gml.Core/src/CmlLib.ExtendedCore/src/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/CmlLib.Core.Installer.NeoForge/CmlLib.Core.Installer.NeoForge/CmlLib.Core.Installer.NeoForge.csproj", "src/Gml.Web.Api/src/Gml.Core/src/CmlLib.Core.Installer.NeoForge/CmlLib.Core.Installer.NeoForge/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/Modrinth.Api/src/Modrinth.Api/Modrinth.Api.csproj", "src/Gml.Web.Api/src/Gml.Core/src/Modrinth.Api/src/Modrinth.Api/"]
COPY ["src/Gml.Web.Api/src/Gml.Core/src/Pingo/Pingo/Pingo.csproj", "src/Gml.Web.Api/src/Gml.Core/src/Pingo/Pingo/"]
COPY ["src/Gml.Web.Api/src/Gml.Web.Api.Domains/Gml.Web.Api.Domains.csproj", "src/Gml.Web.Api/src/Gml.Web.Api.Domains/"]
COPY ["src/Gml.Web.Api/src/Gml.Web.Api.Dto/Gml.Web.Api.Dto.csproj", "src/Gml.Web.Api/src/Gml.Web.Api.Dto/"]
COPY ["src/Gml.Web.Api/src/plugins/Gml.Web.Api.EndpointSDK/Gml.Web.Api.EndpointSDK.csproj", "src/plugins/Gml.Web.Api/src/Gml.Web.Api.EndpointSDK/"]
RUN dotnet restore "src/Gml.Web.Api/src/Gml.Web.Api/Gml.Web.Api.csproj"
COPY . .
WORKDIR "/src/src/Gml.Web.Api/src/Gml.Web.Api"
RUN dotnet build "Gml.Web.Api.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Gml.Web.Api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Gml.Web.Api.dll"]
