import http from 'http';
import PG from 'pg';
import client from 'prom-client'; 

const PORT = process.env.PORT || 3000;

// 2. coletor de métricas
const register = new client.Registry();
client.collectDefaultMetrics({ register });


const pool = new PG.Pool({
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

const server = http.createServer(async (req, res) => {
  console.log(`Request: ${req.url}`);

  // 3. rota '/metrics' para o Prometheus
  if (req.url === '/metrics') {
    res.setHeader('Content-Type', register.contentType);
    res.end(await register.metrics());
    return;
  }
  
  
  // CORS para todas as outras respostas
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Content-Type', 'application/json');

  if (req.url === "/") {
    //lógica funcional da rota principal aqui dentro
    let dbClient;
    try {
      dbClient = await pool.connect();
      const result = (await dbClient.query("SELECT * FROM users WHERE role = 'admin'")).rows[0];

      const data = {
        database: true,
        userAdmin: result?.role === "admin"
      };
      
      res.writeHead(200);
      res.end(JSON.stringify(data));

    } catch (error) {
      console.error('Erro ao executar a query ou conectar ao banco:', error.stack);
      const data = { database: false, userAdmin: false };
      res.writeHead(500);
      res.end(JSON.stringify(data));

    } finally {
      if (dbClient) {
        dbClient.release();
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