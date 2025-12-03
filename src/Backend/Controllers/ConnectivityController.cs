using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Microsoft.Data.SqlClient;
using Amazon.S3;
using Amazon.S3.Model;
using StackExchange.Redis;
using System.Text.Json;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ConnectivityController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IAmazonS3 _s3Client;
    private readonly IConnectionMultiplexer _redis;

    public ConnectivityController(IConfiguration configuration, IAmazonS3 s3Client, IConnectionMultiplexer redis = null)
    {
        _configuration = configuration;
        _s3Client = s3Client;
        _redis = redis;
    }

    [HttpGet]
    public IActionResult Get()
    {
        var results = new
        {
            timestamp = DateTime.UtcNow,
            tests = new
            {
                postgresql = new { status = "READY", message = "Click to test", duration_ms = 0 },
                sqlserver = new { status = "READY", message = "Click to test", duration_ms = 0 },
                redis_cache = new { status = "READY", message = "Click to test", duration_ms = 0 },
                s3_static = new { status = "READY", message = "Click to test", duration_ms = 0 }
            }
        };

        var html = GenerateHtml(results);
        return Content(html, "text/html");
    }

    [HttpGet("json")]
    public async Task<IActionResult> GetJson()
    {
        var results = new
        {
            timestamp = DateTime.UtcNow,
            tests = new
            {
                postgresql = await TestPostgreSQL(),
                sqlserver = await TestSqlServer(),
                redis_cache = await TestRedisCache(),
                s3_static = await TestS3Static()
            }
        };

        return Ok(results);
    }

    [HttpGet("test/postgresql")]
    public async Task<IActionResult> TestPostgreSQLEndpoint()
    {
        var result = await TestPostgreSQL();
        return Ok(result);
    }

    [HttpGet("test/sqlserver")]
    public async Task<IActionResult> TestSqlServerEndpoint()
    {
        var result = await TestSqlServer();
        return Ok(result);
    }

    [HttpGet("test/redis")]
    public async Task<IActionResult> TestRedisEndpoint()
    {
        var result = await TestRedisCache();
        return Ok(result);
    }

    [HttpGet("test/s3")]
    public async Task<IActionResult> TestS3Endpoint()
    {
        var result = await TestS3Static();
        return Ok(result);
    }



    private async Task<object> TestPostgreSQL()
    {
        try
        {
            var secretJson = _configuration["POSTGRESQL_CONNECTION"];
            if (string.IsNullOrEmpty(secretJson)) return new { status = "FAIL", error = "Connection string not found", duration_ms = 0 };

            var secret = JsonSerializer.Deserialize<JsonElement>(secretJson);
            var host = secret.GetProperty("host").GetString();
            var port = secret.GetProperty("port").GetInt32();
            var database = secret.GetProperty("dbInit").GetString();
            var username = secret.GetProperty("username").GetString();
            var password = secret.GetProperty("password").GetString();

            var connectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password};";
            var startTime = DateTime.UtcNow;
            
            using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync();
            
            using var command = new NpgsqlCommand("SELECT version()", connection);
            var versionObj = await command.ExecuteScalarAsync();
            var version = versionObj?.ToString();
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;

            return new { status = "OK", version = version?.Substring(0, Math.Min(50, version?.Length ?? 0)), duration_ms = Math.Round(duration, 2) };
        }
        catch (Exception ex)
        {
            return new { status = "FAIL", error = ex.Message, duration_ms = 0 };
        }
    }

    private async Task<object> TestSqlServer()
    {
        try
        {
            var secretJson = _configuration["SQLSERVER_CONNECTION"];
            if (string.IsNullOrEmpty(secretJson)) return new { status = "FAIL", error = "Connection string not found", duration_ms = 0 };

            var secret = JsonSerializer.Deserialize<JsonElement>(secretJson);
            var host = secret.GetProperty("host").GetString();
            var port = secret.GetProperty("port").GetInt32();
            var database = secret.GetProperty("dbInit").GetString();
            var username = secret.GetProperty("username").GetString();
            var password = secret.GetProperty("password").GetString();

            var connectionString = $"Server={host},{port};Database={database};User Id={username};Password={password};TrustServerCertificate=true;";
            var startTime = DateTime.UtcNow;
            
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();
            
            using var command = new SqlCommand("SELECT @@VERSION", connection);
            var versionObj = await command.ExecuteScalarAsync();
            var version = versionObj?.ToString();
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;

            return new { status = "OK", version = version?.Substring(0, Math.Min(50, version?.Length ?? 0)), duration_ms = Math.Round(duration, 2) };
        }
        catch (Exception ex)
        {
            return new { status = "FAIL", error = ex.Message, duration_ms = 0 };
        }
    }

    private async Task<object> TestRedisCache()
    {
        try
        {
            if (_redis == null)
            {
                return new { status = "DISABLED", message = "Redis not configured", duration_ms = 0 };
            }
            
            var startTime = DateTime.UtcNow;
            var database = _redis.GetDatabase();
            
            var testKey = $"connectivity-test-{DateTime.UtcNow:yyyyMMdd-HHmmss}";
            var testValue = $"Backend connectivity test at {DateTime.UtcNow}";
            
            // Test SET operation
            await database.StringSetAsync(testKey, testValue, TimeSpan.FromMinutes(1));
            
            // Test GET operation
            var retrievedValue = await database.StringGetAsync(testKey);
            
            // Test DELETE operation
            await database.KeyDeleteAsync(testKey);
            
            // Verify the value was retrieved correctly
            var isSuccess = retrievedValue.HasValue && retrievedValue == testValue;
            
            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;
            
            return new { 
                status = isSuccess ? "OK" : "FAIL", 
                operation = "set/get/delete", 
                duration_ms = Math.Round(duration, 2),
                endpoint = _redis.GetEndPoints().FirstOrDefault()?.ToString()
            };
        }
        catch (Exception ex)
        {
            return new { status = "FAIL", error = ex.Message, duration_ms = 0 };
        }
    }

    private async Task<object> TestS3Static()
    {
        try
        {
            var bucketName = _configuration["S3_STATIC_BUCKET"] ?? "aqua-cicd-app-uat-static";
            var startTime = DateTime.UtcNow;

            var testKey = $"connectivity-test-{DateTime.UtcNow:yyyyMMdd-HHmmss}.txt";
            var testContent = $"Connectivity test from Backend at {DateTime.UtcNow}";
            
            await _s3Client.PutObjectAsync(new PutObjectRequest
            {
                BucketName = bucketName,
                Key = testKey,
                ContentBody = testContent,
                ContentType = "text/plain"
            });

            var response = await _s3Client.GetObjectAsync(bucketName, testKey);
            using var reader = new StreamReader(response.ResponseStream);
            var content = await reader.ReadToEndAsync();

            await _s3Client.DeleteObjectAsync(bucketName, testKey);

            var duration = (DateTime.UtcNow - startTime).TotalMilliseconds;
            return new { status = "OK", operation = "read/write/delete", duration_ms = Math.Round(duration, 2) };
        }
        catch (Exception ex)
        {
            return new { status = "FAIL", error = ex.Message, duration_ms = 0 };
        }
    }



    private string GenerateHtml(object results)
    {
        var json = JsonSerializer.Serialize(results, new JsonSerializerOptions { WriteIndented = true });
        var resultsData = JsonSerializer.Deserialize<dynamic>(json);
        
        return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>🔗 AQUA E-WARRANTY BACKEND</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh; }}
        .container {{ max-width: 1200px; margin: 0 auto; padding: 20px; }}
        .header {{ text-align: center; margin-bottom: 40px; }}
        .header h1 {{ font-size: 2.5em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }}
        .timestamp {{ background: rgba(255,255,255,0.1); padding: 10px 20px; border-radius: 25px; display: inline-block; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 25px; margin-bottom: 30px; }}
        .card {{ background: rgba(255,255,255,0.1); border-radius: 20px; padding: 25px; border: 1px solid rgba(255,255,255,0.2); backdrop-filter: blur(10px); }}
        .card-header {{ display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }}
        .card-title {{ font-size: 1.3em; font-weight: bold; }}
        .status-badge {{ padding: 8px 16px; border-radius: 20px; font-weight: bold; font-size: 0.9em; text-transform: uppercase; }}
        .status-badge.ok {{ background: linear-gradient(45deg, #10b981, #34d399); }}
        .status-badge.fail {{ background: linear-gradient(45deg, #ef4444, #f87171); }}
        .status-badge.ready {{ background: linear-gradient(45deg, #6b7280, #9ca3af); }}
        .status-badge.testing {{ background: linear-gradient(45deg, #f59e0b, #fbbf24); }}
        .metric {{ display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid rgba(255,255,255,0.1); }}
        .metric:last-child {{ border-bottom: none; }}
        .metric-label {{ font-weight: 500; opacity: 0.8; }}
        .metric-value {{ font-weight: bold; color: #fbbf24; }}
        .btn {{ background: linear-gradient(45deg, #10b981, #34d399); color: white; border: none; padding: 8px 16px; border-radius: 15px; font-size: 0.8em; margin-top: 10px; cursor: pointer; }}
        .actions {{ text-align: center; margin-top: 40px; }}
        .btn-large {{ background: linear-gradient(45deg, #3b82f6, #1d4ed8); color: white; border: none; padding: 15px 30px; border-radius: 25px; font-size: 1em; font-weight: bold; cursor: pointer; margin: 0 10px; text-decoration: none; display: inline-block; }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🏭 AQUA E-WARRANTY BACKEND</h1>
            <div style='font-size: 1.2em; margin-bottom: 20px;'>Multi-Service Backend Connectivity</div>
            <div class='timestamp'>📅 Last Test: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC</div>
        </div>
        
        <div class='grid'>
            <div class='card' id='postgresql-card'>
                <div class='card-header'>
                    <div class='card-title'>🐘 PostgreSQL</div>
                    <div class='status-badge ready' id='postgresql-status'>READY</div>
                </div>
                <div class='metrics' id='postgresql-metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value' id='postgresql-duration'>0 ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔐 Auth</span>
                        <span class='metric-value'>Secrets Manager</span>
                    </div>
                    <div class='metric' id='postgresql-result' style='display:none;'>
                        <span class='metric-label'>📊 Result</span>
                        <span class='metric-value' id='postgresql-message'></span>
                    </div>
                    <button class='btn' onclick='testPostgreSQL()'>🧪 Test Connection</button>
                </div>
            </div>
            
            <div class='card' id='sqlserver-card'>
                <div class='card-header'>
                    <div class='card-title'>🗄️ SQL Server</div>
                    <div class='status-badge ready' id='sqlserver-status'>READY</div>
                </div>
                <div class='metrics' id='sqlserver-metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value' id='sqlserver-duration'>0 ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔐 Auth</span>
                        <span class='metric-value'>Secrets Manager</span>
                    </div>
                    <div class='metric' id='sqlserver-result' style='display:none;'>
                        <span class='metric-label'>📊 Result</span>
                        <span class='metric-value' id='sqlserver-message'></span>
                    </div>
                    <button class='btn' onclick='testSqlServer()'>🧪 Test Connection</button>
                </div>
            </div>
            
            <div class='card' id='redis-card'>
                <div class='card-header'>
                    <div class='card-title'>🔴 Redis Cache</div>
                    <div class='status-badge ready' id='redis-status'>READY</div>
                </div>
                <div class='metrics' id='redis-metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value' id='redis-duration'>0 ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔧 Operation</span>
                        <span class='metric-value'>SET/GET/DELETE</span>
                    </div>
                    <div class='metric' id='redis-result' style='display:none;'>
                        <span class='metric-label'>📊 Result</span>
                        <span class='metric-value' id='redis-message'></span>
                    </div>
                    <button class='btn' onclick='testRedis()'>🧪 Test Connection</button>
                </div>
            </div>
            
            <div class='card' id='s3-card'>
                <div class='card-header'>
                    <div class='card-title'>📦 S3 Static</div>
                    <div class='status-badge ready' id='s3-status'>READY</div>
                </div>
                <div class='metrics' id='s3-metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value' id='s3-duration'>0 ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔧 Operation</span>
                        <span class='metric-value'>PUT/GET/DELETE</span>
                    </div>
                    <div class='metric' id='s3-result' style='display:none;'>
                        <span class='metric-label'>📊 Result</span>
                        <span class='metric-value' id='s3-message'></span>
                    </div>
                    <button class='btn' onclick='testS3()'>🧪 Test Connection</button>
                </div>
            </div>
        </div>
        
        <div class='actions'>
            <button class='btn-large' onclick='location.reload()'>🔄 Run Tests Again</button>
            <a href='/api/connectivity/json' target='_blank' class='btn-large'>📋 JSON Results</a>
            <a href='/api/health' class='btn-large'>❤️ System Health</a>
        </div>
    </div>
    
    <script>
        function updateStatus(service, status, duration, message) {{
            const statusEl = document.getElementById(service + '-status');
            const durationEl = document.getElementById(service + '-duration');
            const resultEl = document.getElementById(service + '-result');
            const messageEl = document.getElementById(service + '-message');
            
            statusEl.textContent = status;
            statusEl.className = 'status-badge ' + status.toLowerCase();
            durationEl.textContent = duration + ' ms';
            
            if (message) {{
                messageEl.textContent = message;
                resultEl.style.display = 'flex';
            }}
        }}
        
        async function testPostgreSQL() {{
            updateStatus('postgresql', 'TESTING', 0, '');
            try {{
                const response = await fetch('/api/connectivity/test/postgresql');
                const result = await response.json();
                updateStatus('postgresql', result.status, result.duration_ms, result.error || result.version || 'Connected');
            }} catch (error) {{
                updateStatus('postgresql', 'FAIL', 0, error.message);
            }}
        }}
        
        async function testSqlServer() {{
            updateStatus('sqlserver', 'TESTING', 0, '');
            try {{
                const response = await fetch('/api/connectivity/test/sqlserver');
                const result = await response.json();
                updateStatus('sqlserver', result.status, result.duration_ms, result.error || result.version || 'Connected');
            }} catch (error) {{
                updateStatus('sqlserver', 'FAIL', 0, error.message);
            }}
        }}
        
        async function testRedis() {{
            updateStatus('redis', 'TESTING', 0, '');
            try {{
                const response = await fetch('/api/connectivity/test/redis');
                const result = await response.json();
                updateStatus('redis', result.status, result.duration_ms, result.error || result.endpoint || 'Connected');
            }} catch (error) {{
                updateStatus('redis', 'FAIL', 0, error.message);
            }}
        }}
        
        async function testS3() {{
            updateStatus('s3', 'TESTING', 0, '');
            try {{
                const response = await fetch('/api/connectivity/test/s3');
                const result = await response.json();
                updateStatus('s3', result.status, result.duration_ms, result.error || 'File operations successful');
            }} catch (error) {{
                updateStatus('s3', 'FAIL', 0, error.message);
            }}
        }}
    </script>
</body>
</html>";
    }
}