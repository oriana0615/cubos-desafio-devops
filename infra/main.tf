# Define o provedor que vamos usar (Docker) e sua versão.
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

# Configura o provedor Docker.
provider "docker" {}

# Cria uma imagem Docker para o backend a partir do seu Dockerfile.
resource "docker_image" "backend_image" {
  name = "backend-desafio:latest"
  build {
    context = "../backend"
  }
}

# Cria uma imagem Docker para o frontend a partir do seu Dockerfile.
resource "docker_image" "frontend_image" {
  name = "frontend-desafio:latest"
  build {
    context = "../frontend"
  }
}

# Cria a rede INTERNA para comunicação entre os contêineres.
resource "docker_network" "internal_network" {
  name     = "internal_network"
  internal = true # Garante que só contêineres possam se comunicar nela.
}

# Cria a rede EXTERNA para expor o frontend ao usuário.
resource "docker_network" "external_network" {
  name = "external_network"
}

# Cria o volume para persistir os dados do banco de dados.
resource "docker_volume" "db_data" {
  name = "db_data_volume"
}

# Cria o contêiner do Banco de Dados (PostgreSQL).
resource "docker_container" "postgres_db" {
  image   = "postgres:15.8"
  name    = "postgres-db"
  restart = "always"

  command = ["postgres", "-c", "listen_addresses=*"]

  networks_advanced {
    name = docker_network.internal_network.name
  }

  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }
  volumes {
    host_path      = abspath("../sql/script.sql")
    container_path = "/docker-entrypoint-initdb.d/script.sql"
    read_only      = true
  }

  healthcheck {
    test     = ["CMD", "pg_isready", "-U", var.db_user, "-d", var.db_name]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Cria o contêiner do Backend (Node.js).
resource "docker_container" "backend" {
  image   = docker_image.backend_image.name
  name    = "backend"
  restart = "always"

  networks_advanced {
    name    = docker_network.internal_network.name
    aliases = ["backend"]
  }

  env = [
    "POSTGRES_HOST=postgres-db",
    "POSTGRES_PORT=5432",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
    "PORT=3000"
  ]

  depends_on = [docker_container.postgres_db]
}

# Cria o contêiner do Frontend (Nginx).
resource "docker_container" "frontend" {
  image   = docker_image.frontend_image.name
  name    = "frontend-proxy"
  restart = "always"

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.external_network.name
  }
  networks_advanced {
    name = docker_network.internal_network.name
  }

  depends_on = [docker_container.backend]
}

# --- DE OBSERVABILIDADE ---

# Cria o contêiner do Prometheus.
resource "docker_container" "prometheus" {
  image   = "prom/prometheus:latest"
  name    = "prometheus"
  restart = "always"

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name    = docker_network.internal_network.name
    aliases = ["prometheus"]
  }

  volumes {
    host_path      = abspath("./prometheus/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  depends_on = [docker_container.backend]
}

# Cria o contêiner do Grafana.
resource "docker_container" "grafana" {
  image   = "grafana/grafana:latest"
  name    = "grafana"
  restart = "always"

  ports {
    internal = 3000
    external = 3001
  }

  networks_advanced {
    name = docker_network.internal_network.name
  }
  networks_advanced {
    name = docker_network.external_network.name
  }

  volumes {
    host_path      = abspath("./grafana/provisioning/")
    container_path = "/etc/grafana/provisioning/"
    read_only      = true
  }

  depends_on = [docker_container.prometheus]
}