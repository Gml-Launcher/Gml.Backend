using System.Collections.Immutable;
using Gml.Core.Launcher;
using Gml.WebApi.Config;
using Gml.WebApi.Core.Auth;
using Gml.WebApi.Core.Handlers;
using Gml.WebApi.Core.Services;
using Gml.WebApi.Core.SignalRHubs;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Gml.WebApi.Core.Auth;

namespace Gml.WebApi.Core.Extensions;

public static class ApplicationExtensions
{
    private const string BasicAuthSchemeName = "BasicAuthentication";

    public static WebApplicationBuilder RegisterServices(this WebApplicationBuilder builder)
    {
        var settings = builder.Configuration.GetSection("ProjectSettings");

        var projectName = settings.GetSection("ProjectName").Value ?? "GamerVIINet";
        var projectPath = settings.GetSection("ProjectPath").Value ?? string.Empty;

        builder.Services
            .Configure<ProjectSettings>(settings)
            .AddSingleton<IGmlManager>(_ => new GmlManager(new GmlSettings(projectName, projectPath)))
            .AddScoped<IAuthService, AuthService>()
            .AddScoped<IFileService, FileService>()
            .AddScoped<IAuthLibService, AuthLibService>()
            .AddHttpClient()
            .AddEndpointsApiExplorer()
            .AddAuthIntegrations()
            .AddSwaggerGen()
            .AddSignalR();

        builder.Services.AddAuthentication(BasicAuthSchemeName)
            .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>(BasicAuthSchemeName, _ => { });

        builder.Services.AddAuthorization(options =>
            options.AddPolicy(BasicAuthSchemeName,
                new AuthorizationPolicyBuilder(BasicAuthSchemeName).RequireAuthenticatedUser().Build()
            ));

        return builder;
    }

    public static WebApplication RegisterRoutes(this WebApplication app)
    {
        app.UseSwagger();
        app.UseSwaggerUI();

        app.UseAuthentication();
        app.UseAuthorization();

        // app.UseHttpsRedirection();

        #region auth

        app.MapPost("/api/auth", AuthHandler.Auth);
        app.MapGet("/api/auth", AuthHandler.GetAuthServices);
        app.MapGet("/api/auth/active", AuthHandler.GetActiveAuthService);
        app.MapPut("/api/auth/active", AuthHandler.UpdateActiveAuthService);

        #endregion

        #region Profiles

        app.MapGet("/api/profiles", RequestHandler.GetClients);
        app.MapPost("/api/profiles", RequestHandler.CreateProfile);
        app.MapDelete("/api/profiles/{profileName}", RequestHandler.DeleteProfile);

        app.MapPost("/api/profiles/info", RequestHandler.GetProfileInfo);
        app.MapPut("/api/profiles/info", RequestHandler.UpdateProfile);
        app.MapPost("/api/profiles/restore", RequestHandler.RestoreProfileInfo);
        app.MapPost("/api/profiles/pack", RequestHandler.PackProfile);

        app.MapPost("/api/file", RequestHandler.LoadFile);
        app.MapGet("/api/file/{fileHash}", RequestHandler.DownloadFile);

        app.MapGet("/api/file/whitelist/{profileName}", RequestHandler.GetProfileWhiteList);
        app.MapPost("/api/file/whitelist", RequestHandler.AddFileToWhiteList);
        app.MapDelete("/api/file/whitelist", RequestHandler.RemoveFileFromWhiteList);

        #endregion

        #region Minecraft

        app.MapGet("/api/minecraft", MinecraftHandler.GetAuthLibMetaData);
        app.MapGet("api/minecraft/sessionserver/session/minecraft/profile/{uuid}", MinecraftHandler.GetProfileInfo);
        app.MapPost("api/minecraft/sessionserver/session/minecraft/join", MinecraftHandler.ServerJoin);
        app.MapGet("api/minecraft/sessionserver/session/minecraft/hasJoined", MinecraftHandler.HasServerJoin);

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
