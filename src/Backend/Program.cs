using Amazon.S3;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add AWS services
builder.Services.AddAWSService<IAmazonS3>();

// Add Redis connection with optional initialization
var redisConnectionString = builder.Configuration.GetConnectionString("Redis");
if (!string.IsNullOrEmpty(redisConnectionString))
{
    try
    {
        builder.Services.AddSingleton<IConnectionMultiplexer>(provider => {
            return ConnectionMultiplexer.Connect(redisConnectionString);
        });
    }
    catch
    {
        // Redis connection failed, continue without it
        builder.Services.AddSingleton<IConnectionMultiplexer>(provider => null);
    }
}
else
{
    // No Redis configured, add null service
    builder.Services.AddSingleton<IConnectionMultiplexer>(provider => null);
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection(); // Disabled for ECS deployment
app.UseAuthorization();
app.MapControllers();

app.Run();