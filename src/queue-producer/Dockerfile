# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY ["src/queue-producer/QueueProducer.csproj", "src/queue-producer/"]
RUN dotnet restore "src/queue-producer/QueueProducer.csproj"

COPY . .
WORKDIR "/src/src/queue-producer"
RUN dotnet publish "QueueProducer.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/runtime:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "QueueProducer.dll"]
