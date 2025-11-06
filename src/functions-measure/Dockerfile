# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["src/functions-measure/FunctionsMeasure.csproj", "src/functions-measure/"]
RUN dotnet restore "src/functions-measure/FunctionsMeasure.csproj"

COPY . .
WORKDIR "/src/src/functions-measure"
RUN dotnet publish "FunctionsMeasure.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0
WORKDIR /home/site/wwwroot
ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    FUNCTIONS_WORKER_RUNTIME=dotnet-isolated \
    AzureWebJobsStorage=UseDevelopmentStorage=true
COPY --from=build /app/publish .
