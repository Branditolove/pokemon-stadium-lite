# Guía de Despliegue - Pokémon Stadium Lite Backend

Esta guía proporciona instrucciones para desplegar el backend en diferentes entornos.

## Despliegue Local

### Requisitos

- Node.js 18+
- MongoDB 4.0+
- npm o yarn

### Pasos

1. **Clonar o descargar el código**

```bash
cd /path/to/pokemon_app/backend
```

2. **Instalar dependencias**

```bash
npm install
```

3. **Crear archivo `.env`**

```bash
cp .env.example .env
```

4. **Configurar variables de entorno**

Editar `.env`:

```
MONGODB_URI=mongodb://localhost:27017/pokemon_stadium
PORT=8080
HOST=0.0.0.0
NODE_ENV=development
```

5. **Iniciar MongoDB**

```bash
# macOS con Homebrew
brew services start mongodb-community

# Linux
sudo systemctl start mongod

# Docker
docker run -d -p 27017:27017 --name mongo mongo:7.0
```

6. **Ejecutar el servidor**

```bash
# Producción
npm start

# Desarrollo con nodemon
npm run dev
```

El servidor estará disponible en `http://localhost:8080`

## Despliegue con Docker

### Requisitos

- Docker 20.10+
- Docker Compose 2.0+ (opcional)

### Con Docker Compose (Recomendado)

```bash
cd /path/to/pokemon_app/backend

# Construir e iniciar contenedores
docker-compose up -d

# Ver logs
docker-compose logs -f backend

# Detener servicios
docker-compose down
```

El servidor estará disponible en `http://localhost:8080`

### Con Docker solo

```bash
# Construir imagen
docker build -t pokemon-backend:latest .

# Ejecutar contenedor
docker run -d \
  --name pokemon-backend \
  -p 8080:8080 \
  -e MONGODB_URI=mongodb://host.docker.internal:27017/pokemon_stadium \
  pokemon-backend:latest

# Ver logs
docker logs -f pokemon-backend

# Detener contenedor
docker stop pokemon-backend
```

## Despliegue en Heroku

### Requisitos

- Cuenta Heroku
- Heroku CLI instalado
- MongoDB Atlas (servicio de base de datos)

### Pasos

1. **Crear aplicación Heroku**

```bash
heroku login
heroku create pokemon-stadium-lite-backend
```

2. **Configurar MongoDB Atlas**

- Crear cuenta en https://www.mongodb.com/cloud/atlas
- Crear cluster gratuito
- Obtener connection string
- Configurar variables de entorno:

```bash
heroku config:set MONGODB_URI="mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/pokemon_stadium?retryWrites=true&w=majority"
heroku config:set PORT=8080
heroku config:set NODE_ENV=production
```

3. **Crear Procfile** (si no existe)

```bash
echo "web: npm start" > Procfile
git add Procfile
git commit -m "Add Procfile for Heroku"
```

4. **Desplegar**

```bash
git push heroku main
```

5. **Ver logs**

```bash
heroku logs --tail
```

## Despliegue en AWS (EC2)

### Requisitos

- Instancia EC2 con Ubuntu 20.04+
- Security Group configurado para puerto 8080
- MongoDB RDS o EC2 MongoDB

### Pasos

1. **SSH a la instancia**

```bash
ssh -i key.pem ubuntu@your-instance-ip
```

2. **Instalar Node.js**

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

3. **Instalar PM2**

```bash
sudo npm install -g pm2
```

4. **Clonar repositorio**

```bash
git clone https://github.com/your-repo/pokemon-stadium-lite.git
cd pokemon-stadium-lite/backend
npm install
```

5. **Configurar variables de entorno**

```bash
nano .env
```

```
MONGODB_URI=mongodb://admin:password@your-mongodb-ip:27017/pokemon_stadium
PORT=8080
NODE_ENV=production
```

6. **Iniciar con PM2**

```bash
pm2 start server.js --name "pokemon-backend"
pm2 save
pm2 startup
```

7. **Configurar Nginx como reverse proxy** (opcional)

```bash
sudo apt-get install -y nginx

# Crear configuración
sudo nano /etc/nginx/sites-available/pokemon

# Contenido:
server {
  listen 80;
  server_name your-domain.com;

  location / {
    proxy_pass http://localhost:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}

# Activar sitio
sudo ln -s /etc/nginx/sites-available/pokemon /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Despliegue en Google Cloud Run

### Requisitos

- Cuenta Google Cloud
- Cloud Run API habilitada
- gcloud CLI instalado

### Pasos

1. **Autenticarse**

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

2. **Crear Dockerfile.gcloud** (con optimizaciones)

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 8080
CMD ["npm", "start"]
```

3. **Crear Secret para MongoDB**

```bash
echo -n "mongodb+srv://user:pass@cluster0.mongodb.net/pokemon_stadium" | \
  gcloud secrets create mongodb-uri --data-file=-
```

4. **Desplegar a Cloud Run**

```bash
gcloud run deploy pokemon-stadium-lite \
  --source . \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --cpu 1 \
  --set-env-vars MONGODB_URI=$(gcloud secrets versions access latest --secret=mongodb-uri),PORT=8080,NODE_ENV=production \
  --allow-unauthenticated
```

## Monitoreo y Mantenimiento

### Logs

**Localmente:**
```bash
npm run dev  # Ver logs en tiempo real
```

**Con PM2:**
```bash
pm2 logs pokemon-backend
```

**Con Docker:**
```bash
docker logs -f pokemon-backend
```

### Healthcheck

```bash
curl http://your-server:8080/health
```

### Reiniciar servidor

**Con PM2:**
```bash
pm2 restart pokemon-backend
pm2 restart all
```

**Con Docker:**
```bash
docker restart pokemon-backend
```

## Consideraciones de Producción

### Seguridad

1. **HTTPS/TLS**
   - Usar Nginx/Apache como reverse proxy
   - Certificados Let's Encrypt (gratuitos)

2. **CORS**
   - Cambiar `CORS origin: '*'` a dominios específicos
   - En `src/app.js`:

   ```javascript
   const io = new Server(httpServer, {
     cors: {
       origin: ["https://your-app-domain.com"],
       methods: ["GET", "POST"]
     }
   });
   ```

3. **Rate Limiting**
   ```bash
   npm install express-rate-limit
   ```

4. **HELMET** (Headers de seguridad)
   ```bash
   npm install helmet
   ```

### Performance

1. **Clustering** (si es necesario)
   - Usar `pm2-auto-pull` para múltiples instancias
   - Load balancer (Nginx, HAProxy)

2. **Caché**
   - Implementar Redis para sesiones
   - Caché de Pokémon

3. **Monitoreo**
   - PM2 Plus (monitoreo y alertas)
   - New Relic
   - Datadog

### Backups

```bash
# Backup de MongoDB
mongodump --uri "mongodb://user:pass@host:27017/pokemon_stadium" \
  --out /backup/pokemon_$(date +%Y%m%d)

# Restaurar
mongorestore /backup/pokemon_20240115
```

## Troubleshooting

### Puerto en uso
```bash
lsof -i :8080
kill -9 <PID>
```

### MongoDB no conecta
```bash
# Verificar conexión
mongo "mongodb://user:pass@host:27017/pokemon_stadium"

# Verificar logs de MongoDB
tail -f /var/log/mongodb/mongod.log
```

### Memory leak
```bash
# Con PM2
pm2 monit

# Con Node profiler
node --inspect server.js
# Abre chrome://inspect en Chrome
```

## Rollback

Con git:
```bash
git revert <commit-hash>
git push
```

Con PM2:
```bash
pm2 restart pokemon-backend
```

Con Docker:
```bash
docker run -d -p 8080:8080 pokemon-backend:previous-tag
```

## Automatización CI/CD

Ejemplo con GitHub Actions (.github/workflows/deploy.yml):

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install dependencies
        run: npm install

      - name: Run tests
        run: npm test

      - name: Deploy to Heroku
        env:
          HEROKU_API_KEY: ${{ secrets.HEROKU_API_KEY }}
        run: |
          git push https://heroku:$HEROKU_API_KEY@git.heroku.com/pokemon-stadium-lite-backend.git main
```

## Soporte

Para problemas o preguntas:

1. Revisar logs
2. Consultar documentación de dependencias
3. Abrir issue en repositorio
4. Contactar al equipo de desarrollo
