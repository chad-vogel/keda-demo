# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["src/cpu-api/CpuApi.csproj", "src/cpu-api/"]
RUN dotnet restore "src/cpu-api/CpuApi.csproj"

COPY . .
WORKDIR "/src/src/cpu-api"
RUN dotnet publish "CpuApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "CpuApi.dll"]
