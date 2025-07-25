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
  image   = "postgres:15.8" # Imagem exigida no desafio.
  name    = "postgres-db"
  restart = "always"      # Reinicia automaticamente.

  # <-- LINHA ADICIONADA PARA RESOLVER A CONEXÃO
  command = ["postgres", "-c", "listen_addresses=*"]

  # Conecta o banco de dados APENAS à rede interna.
  networks_advanced {
    name = docker_network.internal_network.name
  }

  # Define as variáveis de ambiente com as credenciais do banco.
  env = [
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
  ]

  # Mapeia os volumes: um para os dados e outro para o script de inicialização.
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }
  volumes {
    host_path      = abspath("../sql/script.sql")
    container_path = "/docker-entrypoint-initdb.d/script.sql"
    read_only      = true
  }

  # Bloco para verificação de saúde.
  healthcheck {
    test     = ["CMD", "pg_isready", "-U", var.db_user, "-d", var.db_name]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
}

# Cria o contêiner do Backend (Node.js).
resource "docker_container" "backend" {
  image = docker_image.backend_image.name
  name  = "backend"
  restart = "always"

  # Conecta o backend APENAS à rede interna e dá a ele o nome 'backend'.
  networks_advanced {
    name    = docker_network.internal_network.name
    aliases = ["backend"]
  }

  # Define as variáveis de ambiente para o backend se conectar ao banco.
  env = [
    "POSTGRES_HOST=postgres-db", # O nome do contêiner do banco.
    "POSTGRES_PORT=5432",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=${var.db_name}",
    "PORT=3000"
  ]

  # Garante que o banco de dados seja criado antes do backend.
  depends_on = [docker_container.postgres_db]
}

# Cria o contêiner do Frontend (Nginx).
resource "docker_container" "frontend" {
  image = docker_image.frontend_image.name
  name  = "frontend-proxy"
  restart = "always"

  # Expõe a porta 80 do contêiner na porta 8080 da sua máquina.
  ports {
    internal = 80
    external = 8080
  }

  # Conecta o frontend a AMBAS as redes.
  networks_advanced {
    name = docker_network.external_network.name
  }
  networks_advanced {
    name = docker_network.internal_network.name
  }

  # Garante que o backend seja criado antes do frontend.
  depends_on = [docker_container.backend]
}