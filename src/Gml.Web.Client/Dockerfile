FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Gml.Web.Client/Gml.Web.Client.csproj", "src/Gml.Web.Client/"]
RUN dotnet restore "src/Gml.Web.Client/Gml.Web.Client.csproj"
COPY . .
WORKDIR "/src/src/Gml.Web.Client"
RUN dotnet build "Gml.Web.Client.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Gml.Web.Client.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Gml.Web.Client.dll"]
