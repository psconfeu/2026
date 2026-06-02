FROM mcr.microsoft.com/powershell:7.5-ubuntu-22.04

SHELL ["/bin/bash", "-lc"]

WORKDIR /app
COPY fortune_oracle.ps1 /app/fortune_oracle.ps1

RUN apt-get update && apt-get install -y fortune && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-File", "/app/fortune_oracle.ps1", "-Port", "8080"]
