var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Swagger is optional; keep for dev diagnostics.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add YARP Reverse Proxy from configuration section "ReverseProxy"
builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Map reverse proxy to handle incoming requests according to config
app.MapReverseProxy();

app.Run();
