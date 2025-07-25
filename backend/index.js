import http from 'http';
import PG from 'pg';

const PORT = process.env.PORT || 3000;

// PASSO 1: Em vez de um 'Client', criamos um 'Pool'.
// O Pool gerencia as conexões de forma mais inteligente e resiliente.
const pool = new PG.Pool({
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

const server = http.createServer(async (req, res) => {
  console.log(`Request: ${req.url}`);

  // Habilitamos o CORS para todas as respostas
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Content-Type', 'application/json');

  if (req.url === "/") {
    let client;
    try {
      // PASSO 2: Para cada requisição, pegamos uma conexão do Pool.
      client = await pool.connect();
      const result = (await client.query("SELECT * FROM users WHERE role = 'admin'")).rows[0];

      const data = {
        database: true, // Se a query funcionou, o banco está OK.
        userAdmin: result?.role === "admin"
      };
      
      res.writeHead(200);
      res.end(JSON.stringify(data));

    } catch (error) {
      console.error('Erro ao executar a query ou conectar ao banco:', error.stack);
      const data = { database: false, userAdmin: false };
      res.writeHead(500); // Erro interno do servidor
      res.end(JSON.stringify(data));

    } finally {
      // PASSO 3: Liberamos a conexão de volta para o Pool, estando ela com erro ou não.
      if (client) {
        client.release();
      }
    }
    return;
  }

  // Se a rota não for a raiz, retorna 404.
  res.writeHead(404);
  res.end(JSON.stringify({ message: "Rota não encontrada" }));
});

server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});





































