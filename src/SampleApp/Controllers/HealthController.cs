using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using System.Net;

namespace SampleApp.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        var html = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>&#128640; AQUA E-WARRANTY HEALTH DASHBOARD</title>
    <style>
        body {{ font-family: 'Segoe UI', Arial; margin: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }}
        .container {{ max-width: 800px; margin: 50px auto; padding: 30px; background: rgba(255,255,255,0.1); border-radius: 20px; backdrop-filter: blur(10px); }}
        .status {{ text-align: center; margin-bottom: 30px; }}
        .healthy {{ color: #4ade80; font-size: 3em; text-shadow: 0 0 20px #4ade80; }}
        .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }}
        .card {{ background: rgba(255,255,255,0.15); padding: 20px; border-radius: 15px; border: 1px solid rgba(255,255,255,0.2); }}
        .card h3 {{ margin: 0 0 15px 0; color: #fbbf24; }}
        .metric {{ display: flex; justify-content: space-between; margin: 10px 0; }}
        .value {{ font-weight: bold; color: #34d399; }}
        .pulse {{ animation: pulse 2s infinite; }}
        @keyframes pulse {{ 0%, 100% {{ opacity: 1; }} 50% {{ opacity: 0.7; }} }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='status'>
            <div class='healthy pulse'>&#9989; SYSTEM HEALTHY</div>
            <h1>&#127973; AQUA E-WARRANTY SERVICE</h1>
        </div>
        <div class='grid'>
            <div class='card'>
                <h3>&#128336; System Status</h3>
                <div class='metric'><span>Status:</span><span class='value'>ONLINE</span></div>
                <div class='metric'><span>Timestamp:</span><span class='value'>{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC</span></div>
                <div class='metric'><span>Uptime:</span><span class='value'>{Environment.TickCount64 / 1000 / 60:F1} minutes</span></div>
            </div>
            <div class='card'>
                <h3>&#128421; Server Info</h3>
                <div class='metric'><span>Hostname:</span><span class='value'>{Environment.MachineName}</span></div>
                <div class='metric'><span>OS:</span><span class='value'>{Environment.OSVersion.Platform}</span></div>
                <div class='metric'><span>Processors:</span><span class='value'>{Environment.ProcessorCount}</span></div>
            </div>
            <div class='card'>
                <h3>&#128190; Memory</h3>
                <div class='metric'><span>Working Set:</span><span class='value'>{Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024:F1} MB</span></div>
                <div class='metric'><span>GC Memory:</span><span class='value'>{GC.GetTotalMemory(false) / 1024 / 1024:F1} MB</span></div>
            </div>
            <div class='card'>
                <h3>&#127760; Network</h3>
                <div class='metric'><span>Local IP:</span><span class='value'>{GetLocalIP()}</span></div>
                <div class='metric'><span>Port:</span><span class='value'>8080</span></div>
            </div>
        </div>
        <div style='text-align: center; margin-top: 30px;'>
            <a href='/api/connectivity' style='display: inline-block; background: linear-gradient(45deg, #10b981, #34d399); color: white; padding: 15px 30px; border-radius: 25px; text-decoration: none; font-weight: bold; margin: 10px; transition: transform 0.3s ease;'>&#128279; Test Connectivity</a>
            <p style='opacity: 0.8; margin-top: 20px;'>&#128260; Auto-refresh every 30 seconds</p>
        </div>
    </div>
    <script>setTimeout(() => location.reload(), 30000);</script>
</body>
</html>";
        return Content(html, "text/html");
    }

    private string GetLocalIP()
    {
        try
        {
            return Dns.GetHostEntry(Dns.GetHostName()).AddressList
                .FirstOrDefault(ip => ip.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)?.ToString() ?? "Unknown";
        }
        catch { return "Unknown"; }
    }
}
