# Database Connection Testing

## Quick Test Command

To test if your server can connect to the database, run:

```bash
cd server   # or ~/ggdeploy/server on production
node test-db-connection.js
```

## What It Checks

The test script will verify:
- ✅ Database server is reachable
- ✅ Credentials are correct
- ✅ Database exists and is accessible
- ✅ Tables can be queried
- ✅ SQL Server version and details

## Expected Output (Success)

```
Testing database connection with config:
{
  server: 'localhost',
  database: 'ggdbmain01',
  authenticationType: 'SQL Server Authentication',
  user: 'epladmin',
  instanceName: 'SQLEXPRESS',
  encrypt: true,
  trustServerCertificate: true
}

Attempting to connect...
✓ Successfully connected to database!

✓ Query successful!
Database: ggdbmain01
Version: Microsoft SQL Server 2019...

✓ Connection closed successfully
```

## Common Issues

### Issue: Connection Timeout

```
Error: Connection timeout
```

**Causes:**
- SQL Server is not running
- Firewall blocking port 1433
- Wrong server address

**Solutions:**
```bash
# Check if SQL Server is running (Linux)
sudo systemctl status mssql-server

# Check if SQL Server is running (Windows)
sc query MSSQL$SQLEXPRESS

# Check firewall
sudo ufw status
```

### Issue: Login Failed

```
Error: Login failed for user 'epladmin'
```

**Causes:**
- Wrong username or password in `.env` file
- SQL Server authentication not enabled
- User doesn't have access to the database

**Solutions:**
- Verify credentials in `server/.env`
- Enable SQL Server authentication (mixed mode)
- Grant user access to database

### Issue: Database Not Found

```
Error: Cannot open database "ggdbmain01"
```

**Causes:**
- Database doesn't exist
- User doesn't have access to this specific database

**Solutions:**
- Create the database
- Grant user permissions to the database

## Environment Variables

The test uses these variables from `server/.env`:

```env
# Required
DB_SERVER=localhost
DB_DATABASE=ggdbmain01
DB_USER=epladmin
DB_PASSWORD=your_password

# Optional
DB_INSTANCE_NAME=SQLEXPRESS
DB_PORT=1433
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=true
```

## Troubleshooting Steps

1. **Verify `.env` file exists**:
   ```bash
   ls -la server/.env
   cat server/.env
   ```

2. **Check SQL Server is running**:
   ```bash
   # Linux
   sudo systemctl status mssql-server

   # Windows
   sc query MSSQL$SQLEXPRESS
   ```

3. **Test network connectivity**:
   ```bash
   # Test port 1433 is open
   telnet localhost 1433
   # or
   nc -zv localhost 1433
   ```

4. **Check logs**:
   ```bash
   pm2 logs gg-lms-server --lines 50
   ```

5. **Run the test**:
   ```bash
   cd server
   node test-db-connection.js
   ```

## Integration with Deployment

The deployment script automatically uses the same configuration, so if this test passes, your application should be able to connect to the database.

After fixing any issues, restart the application:

```bash
pm2 restart gg-lms-server
```
