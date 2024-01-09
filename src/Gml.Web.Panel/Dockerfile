FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/Gml.Web.Panel/GmlAdminPanel.csproj", "src/Gml.Web.Panel/"]
RUN dotnet restore "src/Gml.Web.Panel/GmlAdminPanel.csproj"
COPY . .
WORKDIR "/src/src/Gml.Web.Panel"
RUN dotnet build "GmlAdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "GmlAdminPanel.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "GmlAdminPanel.dll"]