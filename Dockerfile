FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Gml.WebApi/Gml.WebApi.csproj", "src/Gml.WebApi/"]
COPY ["src/gml-core/src/GmlCore.Interfaces/GmlCore.Interfaces.csproj", "src/gml-core/src/GmlCore.Interfaces/"]
COPY ["src/gml-core/src/GmlCore/GmlCore.csproj", "src/gml-core/src/GmlCore/"]
COPY ["src/gml-core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge.csproj", "src/gml-core/src/CmlLib.Core.Installer.Forge/CmlLib.Core.Installer.Forge/"]
COPY ["src/Gml.Common/Gml.Common/Gml.Common.csproj", "src/Gml.Common/Gml.Common/"]
COPY ["src/Gml.WebApi.Models/Gml.WebApi.Models.csproj", "src/Gml.WebApi.Models/"]
RUN dotnet restore "src/Gml.WebApi/Gml.WebApi.csproj"
COPY . .
WORKDIR "/src/src/Gml.WebApi"
RUN dotnet build "Gml.WebApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Gml.WebApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Gml.WebApi.dll"]
