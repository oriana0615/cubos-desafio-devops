# Usa uma imagem oficial do Node.js como base. A versão 'alpine' é bem leve.
FROM node:18-alpine

# Define o diretório de trabalho dentro do contêiner.
WORKDIR /app

# Copia os arquivos de dependências e instala elas.
# Fazer isso em um passo separado aproveita o cache do Docker.
COPY package*.json ./
RUN npm install

# Copia o resto dos arquivos da aplicação para o diretório de trabalho.
COPY . .

# Expõe a porta 3000, que é a porta que o nosso backend vai usar.
EXPOSE 3000

# Define o comando que será executado quando o contêiner iniciar.
CMD ["node", "index.js"]