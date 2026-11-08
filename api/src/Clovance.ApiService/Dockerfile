# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy solution and project files
COPY ["api/Directory.Packages.props", "api/"]
COPY ["api/Directory.Build.props", "api/"]
COPY ["api/nuget.config", "api/"]
COPY ["api/src/Clovance.ApiService/Clovance.ApiService.csproj", "api/src/Clovance.ApiService/"]
COPY ["api/aspire/Clovance.ServiceDefaults/Clovance.ServiceDefaults.csproj", "api/aspire/Clovance.ServiceDefaults/"]

# Restore dependencies
RUN dotnet restore "api/src/Clovance.ApiService/Clovance.ApiService.csproj"

# Copy all source files
COPY api/ api/

# Build the application
WORKDIR "/src/api/src/Clovance.ApiService"
RUN dotnet build "Clovance.ApiService.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Clovance.ApiService.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

COPY --from=publish /app/publish .

# The upstream base (Ubuntu 24.04) still ships apt 2.8.3 with fixable HIGH findings
# (CVE-2026-109518, fixed in 2.8.4ubuntu0.1), so a plain rebuild is not enough.
# Upgrading only these two packages keeps the rest of the base image unchanged; the
# list is explicit so a routine package bump cannot alter the runtime unnoticed.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends --only-upgrade apt libapt-pkg6.0t64 \
	&& rm -rf /var/lib/apt/lists/*

# The app generates its JWT signing key (and the data protection keys) under its own home
# directory at startup, so it needs write access there. Nothing under /app is writable.
RUN chown -R app:app /home/app

USER app
ENTRYPOINT ["dotnet", "Clovance.ApiService.dll"]