# Desafio Técnico DevOps - Cubos DevOps

Este projeto implementa um ambiente de desenvolvimento local, seguro e totalmente containerizado, utilizando Docker e Terraform para orquestrar uma arquitetura de três camadas: Frontend, Backend e Banco de Dados. Adicionalmente, uma stack de observabilidade com Prometheus e Grafana foi incluída como funcionalidade extra.

## Índice

- [Arquitetura](#arquitetura)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Tecnologias e Dependências](#tecnologias-e-dependências)
- [Como Executar (Comandos de Inicialização)](#como-executar-comandos-de-inicialização)
- [Verificação e Testes](#verificação-e-testes)
- [Extras (Observabilidade)](#extras-observabilidade)
- [Comandos Principais do Terraform](#comandos-principais-do-terraform)

## Arquitetura

O ambiente foi projetado para ser seguro e replicável, separando os serviços em redes distintas para controlar o acesso.

- **Rede Externa:** Uma rede acessível pelo usuário, onde apenas os serviços de Frontend e Grafana estão expostos.
- **Rede Interna:** Uma rede isolada onde todos os serviços (Frontend, Backend, Banco de Dados, Prometheus, Grafana) se comunicam de forma segura. Essa rede não pode ser acessada diretamente pelo usuário.

Os serviços são:
1.  **Frontend (Proxy Reverso):** Um contêiner Nginx que serve a aplicação web estática (HTML/JS) e atua como um proxy reverso. Todas as requisições para a rota `/api` são encaminhadas para o serviço de Backend.
2.  **Backend:** Uma aplicação em Node.js que recebe requisições do frontend, processa a lógica de negócio, se comunica com o banco de dados e expõe métricas para o Prometheus na rota `/metrics`. Este serviço é inacessível diretamente pelo usuário.
3.  **Banco de Dados:** Um contêiner PostgreSQL 15.8. Ele é inicializado com um script SQL e seus dados são persistidos através de um volume Docker. As credenciais são gerenciadas por variáveis de ambiente.
4.  **Prometheus:** Um contêiner que coleta e armazena as métricas expostas pelo Backend.
5.  **Grafana:** Um contêiner que se conecta ao Prometheus como fonte de dados para criar dashboards e visualizar as métricas.

## Estrutura de Pastas

A estrutura final do projeto, incluindo os extras de observabilidade.

```
/cubos-desafio-devops
|-- .gitignore
|-- README.md
|-- /backend
|   |-- Dockerfile
|   |-- index.js
|   |-- package.json
|   +-- package-lock.json
|
|-- /frontend
|   |-- Dockerfile
|   |-- index.html
|   +-- nginx.conf
|
|-- /infra
|   |-- /grafana
|   |   +-- /provisioning
|   |       +-- /datasources
|   |           +-- prometheus.yml
|   |
|   |-- /prometheus
|   |   +-- prometheus.yml
|   |
|   |-- main.tf
|   +-- variables.tf
|
|-- /sql
|   +-- script.sql
```

## Tecnologias e Dependências

### Pré-requisitos de Ambiente
Ferramentas que precisam estar instaladas na sua máquina.

- **Docker:** Plataforma de containerização utilizada para rodar todos os serviços de forma isolada. [Link para Instalação](https://www.docker.com/get-started/).
- **Terraform:** Ferramenta de Infraestrutura como Código usada para automatizar a criação e gerenciamento de todos os recursos Docker (contêineres, redes, volumes). [Link para Instalação](https://www.terraform.io/downloads.html).
- **Node.js e npm:** Necessário para instalar as dependências do backend localmente e gerar o arquivo `package-lock.json`. [Link para Instalação](https://nodejs.org/).

### Dependências do Backend
Bibliotecas Node.js utilizadas no projeto, definidas em `backend/package.json`.

- **pg:** Cliente PostgreSQL para Node.js, utilizado para a comunicação entre o backend e o banco de dados.
- **prom-client:** Biblioteca utilizada para instrumentar a aplicação e expor as métricas no formato que o Prometheus entende.

## Como Executar (Comandos de Inicialização)

Siga os passos abaixo para subir todo o ambiente.

1.  **Clone o Repositório:**
    Baixe os arquivos do projeto para a sua máquina.
    ```bash
    git clone (https://github.com/oriana0615/cubos-desafio-devops.git)
    cd cubos-desafio-devops
    ```
2.  **Instale as Dependências do Backend:**
    Este passo é necessário para gerar o `package-lock.json`.
    ```bash
    cd backend
    npm install
    cd ..
    ```
3.  **Navegue até a Pasta de Infraestrutura:**
    Todos os comandos do Terraform devem ser executados a partir desta pasta.
    ```bash
    cd infra
    ```
4.  **Inicialize o Terraform:**
    Este comando prepara o ambiente, baixando o provedor Docker.
    ```bash
    terraform init
    ```
5.  **Aplique a Configuração:**
    Este comando constrói as imagens e sobe todos os cinco contêineres.
    ```bash
    terraform apply -auto-approve
    ```
6.  **Acesse os Serviços:**
    Após a conclusão, os seguintes serviços estarão disponíveis:
    - **Aplicação Principal:** [http://localhost:8080](http://localhost:8080)
    - **Prometheus:** [http://localhost:9090](http://localhost:9090)
    - **Grafana:** [http://localhost:3001](http://localhost:3001) (login: `*` / `*`)

## Verificação e Testes

Comandos e ações para comprovar que todos os requisitos do desafio foram cumpridos.

- **Teste de Funcionalidade da Aplicação:**
    - **Como Fazer:** Acesse `http://localhost:8080` e clique no botão.
    - **Resultado Esperado:** As mensagens "Database is up" e "Migration runned" aparecem na tela.

- **Teste da Política de Reinício Automático:**
    - **Como Fazer:** No terminal, execute `docker kill backend`. Aguarde 10 segundos e depois execute `docker ps`.
    - **Resultado Esperado:** O contêiner `backend` deve ter reaparecido na lista, provando que a política `restart = "always"` funcionou.

- **Teste da Segurança da Rede:**
    - **Como Fazer:** Tente acessar o backend (`http://localhost:3000`) ou o banco de dados (`http://localhost:5432`) diretamente pelo navegador.
    - **Resultado Esperado:** A conexão será recusada, provando que eles estão seguros na rede interna.

- **Teste de Persistência de Dados:**
    - **Como Fazer:** Execute `terraform destroy -auto-approve` e depois `terraform apply -auto-approve` novamente. Acesse a aplicação em `http://localhost:8080` e clique no botão.
    - **Resultado Esperado:** A aplicação deve funcionar normalmente, provando que os dados do banco persistiram no volume Docker mesmo após o contêiner ser destruído e recriado.

- **Teste do Prometheus (Coleta de Métricas):**
    - **Como Fazer:** Acesse a UI do Prometheus em `http://localhost:9090`. No menu, vá em "Status" -> "Targets".
    - **Resultado Esperado:** O `backend` deve estar listado com o estado "UP" (verde), provando que o Prometheus está coletando as métricas com sucesso.

- **Teste do Grafana (Visualização de Métricas):**
    - **Como Fazer:**
        1.  Acesse a interface do Grafana em `http://localhost:3001` (login: `*`/`*`).
        2.  No menu, vá em "Dashboards" -> "New" -> "New Dashboard".
        3.  Clique em "Add visualization" e selecione a fonte de dados "Prometheus".
        4.  No campo "Metrics browser", digite `process_cpu_user_seconds_total` e selecione a métrica.
    - **Resultado Esperado:**
        Um gráfico deve aparecer no painel, mostrando os dados de uso da CPU do `backend`. Isso prova que o Grafana está conectado ao Prometheus e visualizando os dados corretamente.

## Extras (Observabilidade)

Este projeto inclui uma stack de monitoramento com Prometheus e Grafana.
- O **Prometheus** está configurado para coletar métricas do endpoint `/metrics` que foi adicionado à aplicação backend.
- O **Grafana** está pré-configurado para usar o Prometheus como fonte de dados, pronto para que você possa criar dashboards e visualizar métricas como uso de CPU e memória da aplicação.

## Comandos Principais do Terraform

Todos os comandos devem ser executados de dentro da pasta `infra`.

- **Subir ou Atualizar o ambiente:**
  ```bash
  terraform apply
  ```

- **Destruir o ambiente:**
  ```bash
  terraform destroy
  ```