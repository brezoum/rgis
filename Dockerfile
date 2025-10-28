# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

ARG LAUNCHING_FROM_VS
ARG FINAL_BASE_IMAGE=${LAUNCHING_FROM_VS:+aotdebug}

# === Base stage (runtime) ===
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

# === Build stage ===
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
RUN apt-get update && apt-get install -y --no-install-recommends clang zlib1g-dev
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# 🔧 Tukaj je glavni popravek – kopiramo celotno vsebino projekta
COPY . .

# 🔧 Zdaj lahko restoraš in gradiš neposredno .csproj
RUN dotnet restore "RGIS-SpletnaKnjigarna.csproj"
RUN dotnet build "RGIS-SpletnaKnjigarna.csproj" -c $BUILD_CONFIGURATION -o /app/build

# === Publish stage ===
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "RGIS-SpletnaKnjigarna.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=true

# === Final runtime image ===
FROM ${FINAL_BASE_IMAGE:-mcr.microsoft.com/dotnet/runtime-deps:8.0} AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "RGIS-SpletnaKnjigarna.dll"]
