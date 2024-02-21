using Gml.Web.Skin.Service.Core.Mapper;
using Gml.Web.Skin.Service.Core.Requests;

namespace Gml.Web.Skin.Service.Core.Extensions.Application;

public static class ApplicationExtensions
{
    public static WebApplicationBuilder CreateService(this WebApplicationBuilder builder)
    {
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();

        builder.Services.AddAutoMapper(typeof(TextureMapper));

        CheckFolders();

        return builder;
    }

    private static void CheckFolders()
    {
        if (!Directory.Exists(SkinHelper.SkinTextureDirectory))
            Directory.CreateDirectory(SkinHelper.SkinTextureDirectory);

        if (!Directory.Exists(SkinHelper.CloakTextureDirectory))
            Directory.CreateDirectory(SkinHelper.CloakTextureDirectory);
    }

    public static WebApplication Run(this WebApplicationBuilder builder)
    {
        var app = builder.Build();

        app.UseSwagger();
        app.UseSwaggerUI();

        // app.UseHttpsRedirection();
        app.AddRoutes();

        app.Run();

        return app;
    }

    private static WebApplication AddRoutes(this WebApplication app)
    {
        app.MapGet("/{userName}", TextureRequests.GetUserTexture);

        app.MapPost("/skin/{userName}", TextureRequests.LoadSkin);
        app.MapGet("/skin/{userName}", TextureRequests.GetSkin);
        app.MapGet("/skin/{userName}/head/{size}", TextureRequests.GetSkinHead);
        app.MapGet("/skin/{userName}/front/{size}", TextureRequests.GetSkinFront);
        app.MapGet("/skin/{userName}/back/{size}", TextureRequests.GetSkinBack);
        app.MapGet("/skin/{userName}/full-back/{size}", TextureRequests.GetSkinAndCloakBack);

        app.MapPost("/cloak/{userName}", TextureRequests.LoadCloak);
        app.MapGet("/cloak/{userName}", TextureRequests.GetCloakTexture);
        app.MapGet("/cloak/{userName}/{size}", TextureRequests.GetCloak);

        app.MapGet("/refresh/{userName}", TextureRequests.RefreshCache);

        return app;
    }
}

// app.MapGet("/weatherforecast", () =>
// {
//     var forecast = Enumerable.Range(1, 5).Select(index =>
//         new WeatherForecast
//         (
//             DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
//             Random.Shared.Next(-20, 55),
//             summaries[Random.Shared.Next(summaries.Length)]
//         ))
//         .ToArray();
//     return forecast;
// })
// .WithName("GetWeatherForecast")
// .WithOpenApi();
