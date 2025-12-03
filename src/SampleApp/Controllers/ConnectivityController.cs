using Microsoft.AspNetCore.Mvc;

using Npgsql;
using Amazon.S3;
using Amazon.S3.Model;
using System.Text.Json;

namespace SampleApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ConnectivityController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IAmazonS3 _s3Client;

    public ConnectivityController(IConfiguration configuration, IAmazonS3 s3Client)
    {
        _configuration = configuration;
        _s3Client = s3Client;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var results = new
        {
            timestamp = DateTime.UtcNow,
            tests = new
            {
                postgresql = new { status = "READY", message = "Click to test", duration_ms = 0 },

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



    private async Task<object> TestS3Static()
    {
        try
        {
            var bucketName = _configuration["S3_STATIC_BUCKET"] ?? "aqua-cicd-app-uat-static";
            var startTime = DateTime.UtcNow;

            var testKey = $"connectivity-test-{DateTime.UtcNow:yyyyMMdd-HHmmss}.txt";
            var testContent = $"Connectivity test from ECS at {DateTime.UtcNow}";
            
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



    private async Task<dynamic?> GetSecret(string secretName)
    {
        try
        {
            using var client = new Amazon.SecretsManager.AmazonSecretsManagerClient();
            var response = await client.GetSecretValueAsync(new Amazon.SecretsManager.Model.GetSecretValueRequest
            {
                SecretId = secretName
            });
            
            return JsonSerializer.Deserialize<dynamic>(response.SecretString);
        }
        catch
        {
            return null;
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
    <title>🔗 AQUA E-WARRANTY CONNECTIVITY</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh; }}
        .container {{ max-width: 1200px; margin: 0 auto; padding: 20px; }}
        .header {{ text-align: center; margin-bottom: 40px; }}
        .header h1 {{ font-size: 2.5em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }}
        .timestamp {{ background: rgba(255,255,255,0.1); padding: 10px 20px; border-radius: 25px; display: inline-block; }}
        
        .overview {{ display: flex; justify-content: center; gap: 30px; margin-bottom: 40px; flex-wrap: wrap; }}
        .overview-item {{ text-align: center; }}
        .overview-circle {{ width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2em; margin: 0 auto 10px; animation: pulse 2s infinite; }}
        .overview-circle.ok {{ background: linear-gradient(45deg, #10b981, #34d399); }}
        .overview-circle.fail {{ background: linear-gradient(45deg, #ef4444, #f87171); }}
        .overview-circle.mixed {{ background: linear-gradient(45deg, #f59e0b, #fbbf24); }}
        
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 25px; margin-bottom: 30px; }}
        .card {{ background: rgba(255,255,255,0.1); border-radius: 20px; padding: 25px; border: 1px solid rgba(255,255,255,0.2); backdrop-filter: blur(10px); transition: transform 0.3s ease; }}
        .card:hover {{ transform: translateY(-5px); }}
        
        .card-header {{ display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }}
        .card-title {{ font-size: 1.3em; font-weight: bold; }}
        .status-badge {{ padding: 8px 16px; border-radius: 20px; font-weight: bold; font-size: 0.9em; text-transform: uppercase; }}
        .status-badge.ok {{ background: linear-gradient(45deg, #10b981, #34d399); }}
        .status-badge.fail {{ background: linear-gradient(45deg, #ef4444, #f87171); }}
        
        .metric {{ display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid rgba(255,255,255,0.1); }}
        .metric:last-child {{ border-bottom: none; }}
        .metric-label {{ font-weight: 500; opacity: 0.8; }}
        .metric-value {{ font-weight: bold; color: #fbbf24; }}
        
        .duration-fast {{ color: #10b981; }}
        .duration-medium {{ color: #f59e0b; }}
        .duration-slow {{ color: #ef4444; }}
        
        .actions {{ text-align: center; margin-top: 40px; }}
        .btn {{ background: linear-gradient(45deg, #3b82f6, #1d4ed8); color: white; border: none; padding: 15px 30px; border-radius: 25px; font-size: 1em; font-weight: bold; cursor: pointer; margin: 0 10px; transition: all 0.3s ease; text-decoration: none; display: inline-block; }}
        .btn:hover {{ transform: translateY(-2px); }}
        .test-btn {{ background: linear-gradient(45deg, #10b981, #34d399); padding: 8px 16px; border-radius: 15px; font-size: 0.8em; margin-top: 10px; }}
        .test-btn:hover {{ background: linear-gradient(45deg, #059669, #10b981); }}
        .test-btn:disabled {{ background: #6b7280; cursor: not-allowed; }}
        .loading {{ opacity: 0.6; }}
        .status-ready {{ background: linear-gradient(45deg, #6b7280, #9ca3af); }}
        
        .auto-refresh {{ margin-top: 20px; opacity: 0.7; font-size: 0.9em; }}
        
        @keyframes pulse {{ 0%, 100% {{ opacity: 1; }} 50% {{ opacity: 0.7; }} }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🔗 AQUA E-WARRANTY</h1>
            <div style='font-size: 1.2em; margin-bottom: 20px;'>Connectivity Test Dashboard</div>
            <div class='timestamp'>📅 Last Test: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC</div>
        </div>
        
        <div class='overview'>
            <div class='overview-item'>
                <div class='overview-circle {GetOverallStatus(resultsData)}'>
                    {GetOverallStatusIcon(resultsData)}
                </div>
                <div>Overall Status</div>
            </div>
            <div class='overview-item'>
                <div class='overview-circle {GetDatabaseStatus(resultsData)}'>
                    🗄️
                </div>
                <div>Databases</div>
            </div>
            <div class='overview-item'>
                <div class='overview-circle {GetS3Status(resultsData)}'>
                    📦
                </div>
                <div>S3 Storage</div>
            </div>
        </div>
        
        <div class='grid'>
            <div class='card'>
                <div class='card-header'>
                    <div class='card-title'>🐘 PostgreSQL</div>
                    <div class='status-badge {GetTestStatus(resultsData, "postgresql")}'>{GetTestStatus(resultsData, "postgresql").ToUpper()}</div>
                </div>
                <div class='metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value {GetDurationClass(resultsData, "postgresql")}' id='pg-duration'>{GetTestDuration(resultsData, "postgresql")} ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>📋 Version</span>
                        <span class='metric-value' id='pg-version'>{GetTestDetails(resultsData, "postgresql")}</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔐 Auth</span>
                        <span class='metric-value'>Secrets Manager</span>
                    </div>
                    <button class='btn test-btn' onclick='testPostgreSQL()' id='pg-btn'>🧪 Test Connection</button>
                </div>
            </div>
            

            
            <div class='card'>
                <div class='card-header'>
                    <div class='card-title'>📁 S3 Static</div>
                    <div class='status-badge {GetTestStatus(resultsData, "s3_static")}' id='s3-status'>{GetTestStatus(resultsData, "s3_static").ToUpper()}</div>
                </div>
                <div class='metrics'>
                    <div class='metric'>
                        <span class='metric-label'>⚡ Response Time</span>
                        <span class='metric-value {GetDurationClass(resultsData, "s3_static")}' id='s3-duration'>{GetTestDuration(resultsData, "s3_static")} ms</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔧 Operations</span>
                        <span class='metric-value' id='s3-operation'>{GetTestOperation(resultsData, "s3_static")}</span>
                    </div>
                    <div class='metric'>
                        <span class='metric-label'>🔐 Auth</span>
                        <span class='metric-value'>IAM Role</span>
                    </div>
                    <button class='btn test-btn' onclick='testS3()' id='s3-btn'>🧪 Test Connection</button>
                </div>
            </div>
        </div>
        
        <div class='actions'>
            <button class='btn' onclick='location.reload()'>🔄 Run Tests Again</button>
            <a href='/api/connectivity/json' target='_blank' class='btn'>📋 JSON Results</a>
            <a href='/api/health' class='btn'>❤️ System Health</a>
        </div>
        
        <div class='auto-refresh'>
            ⏱️ Auto-refresh in <span id='countdown'>60</span> seconds
        </div>
    </div>
    
    <script>
        let countdown = 60;
        setInterval(() => {{
            countdown--;
            document.getElementById('countdown').textContent = countdown;
            if (countdown <= 0) location.reload();
        }}, 1000);
        
        async function testPostgreSQL() {{
            const btn = document.getElementById('pg-btn');
            const status = document.querySelector('.card:nth-child(1) .status-badge');
            const duration = document.getElementById('pg-duration');
            const version = document.getElementById('pg-version');
            
            btn.disabled = true;
            btn.textContent = '🔄 Testing...';
            status.className = 'status-badge loading';
            status.textContent = 'TESTING';
            
            try {{
                const response = await fetch('/api/connectivity/test/postgresql');
                const result = await response.json();
                
                status.className = `status-badge ${{result.status.toLowerCase()}}`;
                status.textContent = result.status;
                duration.textContent = `${{result.duration_ms}} ms`;
                version.textContent = result.version || result.error || 'N/A';
                duration.className = `metric-value ${{getDurationClass(result.duration_ms)}}`;
            }} catch (error) {{
                status.className = 'status-badge fail';
                status.textContent = 'FAIL';
                version.textContent = error.message;
            }}
            
            btn.disabled = false;
            btn.textContent = '🧪 Test Again';
        }}
        

        
        async function testS3() {{
            const btn = document.getElementById('s3-btn');
            const status = document.getElementById('s3-status');
            const duration = document.getElementById('s3-duration');
            const operation = document.getElementById('s3-operation');
            
            btn.disabled = true;
            btn.textContent = '🔄 Testing...';
            status.className = 'status-badge loading';
            status.textContent = 'TESTING';
            
            try {{
                const response = await fetch('/api/connectivity/test/s3');
                const result = await response.json();
                
                status.className = `status-badge ${{result.status.toLowerCase()}}`;
                status.textContent = result.status;
                duration.textContent = `${{result.duration_ms}} ms`;
                operation.textContent = result.operation || result.error || 'N/A';
                duration.className = `metric-value ${{getDurationClass(result.duration_ms)}}`;
            }} catch (error) {{
                status.className = 'status-badge fail';
                status.textContent = 'FAIL';
                operation.textContent = error.message;
            }}
            
            btn.disabled = false;
            btn.textContent = '🧪 Test Again';
        }}
        
        function getDurationClass(duration) {{
            if (duration < 100) return 'duration-fast';
            if (duration < 500) return 'duration-medium';
            return 'duration-slow';
        }}
    </script>
</body>
</html>";
    }

    private string GetTestStatus(dynamic data, string testName)
    {
        try
        {
            return data.GetProperty("tests").GetProperty(testName).GetProperty("status").GetString()?.ToLower() ?? "unknown";
        }
        catch { return "unknown"; }
    }

    private string GetTestDuration(dynamic data, string testName)
    {
        try
        {
            return data.GetProperty("tests").GetProperty(testName).GetProperty("duration_ms").ToString() ?? "0";
        }
        catch { return "0"; }
    }

    private string GetTestDetails(dynamic data, string testName)
    {
        try
        {
            var test = data.GetProperty("tests").GetProperty(testName);
            if (test.TryGetProperty("version", out JsonElement version))
                return version.GetString() ?? "N/A";
            if (test.TryGetProperty("error", out JsonElement error))
                return error.GetString() ?? "N/A";
            return "N/A";
        }
        catch { return "N/A"; }
    }

    private string GetTestOperation(dynamic data, string testName)
    {
        try
        {
            return data.GetProperty("tests").GetProperty(testName).GetProperty("operation").GetString() ?? "N/A";
        }
        catch { return "N/A"; }
    }

    private string GetOverallStatus(dynamic data)
    {
        try
        {
            var statuses = new[] { "postgresql", "s3_static" }
                .Select(test => GetTestStatus(data, test))
                .ToList();
            
            if (statuses.All(s => s == "ok")) return "ok";
            if (statuses.All(s => s == "fail")) return "fail";
            if (statuses.All(s => s == "ready")) return "ready";
            return "mixed";
        }
        catch { return "ready"; }
    }

    private string GetOverallStatusIcon(dynamic data)
    {
        var status = GetOverallStatus(data);
        return status switch
        {
            "ok" => "✅",
            "fail" => "❌",
            _ => "⚠️"
        };
    }

    private string GetDatabaseStatus(dynamic data)
    {
        try
        {
            return GetTestStatus(data, "postgresql");
        }
        catch { return "ready"; }
    }

    private string GetS3Status(dynamic data)
    {
        try
        {
            return GetTestStatus(data, "s3_static");
        }
        catch { return "ready"; }
    }

    private string GetDurationClass(dynamic data, string testName)
    {
        try
        {
            var duration = double.Parse(GetTestDuration(data, testName));
            if (duration < 100) return "duration-fast";
            if (duration < 500) return "duration-medium";
            return "duration-slow";
        }
        catch { return "duration-medium"; }
    }
}