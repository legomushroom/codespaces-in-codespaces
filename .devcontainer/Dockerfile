FROM mcr.microsoft.com/dotnet/core/sdk:3.1.200

EXPOSE 5000

ENV NODE_VERSION=12.18.1

# set up node & yarn & azure cli
RUN cd ~ \
    # install nodejs 12.x
    && curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh && bash nodesource_setup.sh && apt install nodejs \
    # install yarn
    && npm i -g yarn \
    # intall Azure CLI
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    # install Azure Credentials Provider for NuGet
    && wget -c https://github.com/microsoft/artifacts-credprovider/releases/download/v0.1.22/Microsoft.NuGet.CredentialProvider.tar.gz -O - | tar -xz -C ~/.nuget
