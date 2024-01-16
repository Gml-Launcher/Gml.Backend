using Gml.Core.Launcher;
using Gml.WebApi.Core.Handlers;
using Gml.WebApi.Core.SignalRHubs;
using GmlCore.Interfaces;

namespace Gml.WebApi.Core.Extensions;

public static class ApplicationExtensions
{
    public static WebApplicationBuilder RegisterServices(this WebApplicationBuilder builder)
    {
        var configuration = builder.Configuration.GetSection("ProjectName").Value
                            ?? throw new Exception("AppSettings error, section 'ProjectName' not found");

        var directory = builder.Configuration.GetSection("ProjectPath").Value
                        ?? throw new Exception("AppSettings error, section 'ProjectPath' not found");

        builder.Services.AddSingleton<IGmlManager>(_ => new GmlManager(new GmlSettings(configuration, directory)));

        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();
        builder.Services.AddSignalR();

        return builder;
    }

    public static WebApplication RegisterRoutes(this WebApplication app)
    {

        app.UseSwagger();
        app.UseSwaggerUI();

        // app.UseHttpsRedirection();

        #region Profiles

        app.MapGet( "/api/profiles", RequestHandler.GetClients);
        app.MapPost("/api/profiles", RequestHandler.CreateProfile);
        app.MapDelete("/api/profiles", RequestHandler.DeleteProfile);


        app.MapPost("/api/profiles/info", RequestHandler.GetProfileInfo);
        app.MapPost("/api/profiles/restore", RequestHandler.RestoreProfileInfo);
        app.MapPost("/api/profiles/pack", RequestHandler.PackProfile);

        app.MapPost("/api/file", RequestHandler.LoadFile);
        app.MapGet("/api/file/{fileHash}", RequestHandler.DownloadFile);

        app.MapGet("/api/file/whitelist/{profileName}", RequestHandler.GetProfileWhiteList);
        app.MapPost("/api/file/whitelist", RequestHandler.AddFileToWhiteList);
        app.MapDelete("/api/file/whitelist", RequestHandler.RemoveFileFromWhiteList);

        #endregion

        app.MapGet("/", () => Results.Ok("Hello world!"));


        app.MapHub<ProfileHub>("/ws/profiles/restore");


        return app;
    }

    public static WebApplication AddMiddlewares(this WebApplication app)
    {
        return app;
    }
}
