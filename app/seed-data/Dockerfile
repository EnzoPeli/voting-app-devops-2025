FROM python:3.9-slim

# add apache bench (ab) tool
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apache2-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /seed

COPY . .

# create POST data files with ab friendly formats
RUN python make-data.py

# Añadir permisos de ejecución al script
RUN chmod +x /seed/generate-votes.sh


CMD ["/seed/generate-votes.sh"]
