# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["src/queue-worker/QueueWorker.csproj", "src/queue-worker/"]
RUN dotnet restore "src/queue-worker/QueueWorker.csproj"

COPY . .
WORKDIR "/src/src/queue-worker"
RUN dotnet publish "QueueWorker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "QueueWorker.dll"]
