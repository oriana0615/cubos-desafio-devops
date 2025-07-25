# Desafio Técnico DevOps - Cubos Academy

Este projeto implementa um ambiente de desenvolvimento local, seguro e totalmente containerizado, utilizando Docker e Terraform para orquestrar uma arquitetura de três camadas: Frontend, Backend e Banco de Dados.

## Índice

- [Arquitetura](#arquitetura)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Pré-requisitos](#pré-requisitos-dependências)
- [Como Executar](#como-executar-comandos-de-inicialização)
- [Comandos Principais](#comandos-principais)
- [Estrutura de Pastas](#estrutura-de-pastas)

## Arquitetura

[cite_start]O ambiente foi projetado para ser seguro e replicável[cite: 15, 17], separando os serviços em redes distintas para controlar o acesso.

- **Rede Externa:** Uma rede acessível pelo usuário, onde apenas o serviço de Frontend está exposto.
- **Rede Interna:** Uma rede isolada onde os serviços de Backend e Banco de Dados se comunicam. [cite_start]Essa rede não pode ser acessada diretamente pelo usuário. [cite: 17]

Os serviços são:
1.  [cite_start]**Frontend (Proxy Reverso):** Um contêiner Nginx que serve a aplicação web estática (HTML/JS) e atua como um proxy reverso[cite: 14]. [cite_start]Todas as requisições para a rota `/api` são encaminhadas para o serviço de Backend. [cite: 28]
2.  **Backend:** Uma aplicação em Node.js que recebe requisições do frontend, processa a lógica de negócio e se comunica com o banco de dados. [cite_start]Este serviço é inacessível diretamente pelo usuário. [cite: 30]
3.  [cite_start]**Banco de Dados:** Um contêiner PostgreSQL 15.8[cite: 32]. [cite_start]Ele é inicializado com um script SQL [cite: 32] [cite_start]e seus dados são persistidos através de um volume Docker para não serem perdidos quando o contêiner é recriado. [cite: 14, 32] [cite_start]As credenciais são gerenciadas por variáveis de ambiente para maior segurança. [cite: 14, 26]

## Tecnologias Utilizadas

- [cite_start]**Docker:** Para containerização de todos os serviços. [cite: 13, 23]
- [cite_start]**Terraform:** Para orquestração da infraestrutura como código (contêineres, redes, volumes). [cite: 13, 24]
- [cite_start]**Node.js (JavaScript):** Para a aplicação Backend. [cite: 13]
- **Nginx:** Para servir o Frontend e como Proxy Reverso.
- [cite_start]**PostgreSQL:** Como Banco de Dados. [cite: 32]

## Pré-requisitos (Dependências)

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas e configuradas em sua máquina:
- **Docker:** [Link para Instalação](https://www.docker.com/get-started/)
- **Terraform:** [Link para Instalação](https://www.terraform.io/downloads.html)

## Como Executar (Comandos de Inicialização)

[cite_start]Siga os passos abaixo para subir todo o ambiente. [cite: 18]

1.  **Clone este repositório:**
    ```bash
    git clone [https://github.com/seu-usuario/seu-repositorio.git](https://github.com/seu-usuario/seu-repositorio.git)
    cd seu-repositorio
    ```

2.  **Navegue até a pasta de infraestrutura:**
    ```bash
    cd infra
    ```

3.  **Inicialize o Terraform:**
    Este comando irá baixar o provedor Docker necessário para o projeto.
    ```bash
    terraform init
    ```

4.  **Aplique a configuração:**
    Este comando irá construir as imagens Docker e criar os contêineres, redes e volumes.
    ```bash
    terraform apply
    ```
    - O Terraform mostrará um plano de execução. Digite `yes` e pressione `Enter` para confirmar.

5.  **Acesse a aplicação:**
    Após a conclusão do `apply`, abra seu navegador e acesse:
    [http://localhost:8080](http://localhost:8080)

    Clique no botão para verificar se a comunicação entre o frontend, backend e banco de dados está funcionando corretamente.

## Comandos Principais

Todos os comandos devem ser executados de dentro da pasta `infra`.

- **Subir o ambiente:**
  ```bash
  terraform apply
  ```

- **Destruir o ambiente:**
  Este comando irá parar e remover todos os contêineres e recursos criados pelo Terraform.
  ```bash
  terraform destroy
  ```

## Estrutura de Pastas

```
/
|-- .gitignore
|-- README.md
|-- /backend
|   |-- Dockerfile
|   |-- index.js
|   |-- package.json
|
|-- /frontend
|   |-- Dockerfile
|   |-- index.html
|   |-- nginx.conf
|
|-- /infra
|   |-- main.tf
|   |-- variables.tf
|
|-- /sql
|   |-- init.sql
```