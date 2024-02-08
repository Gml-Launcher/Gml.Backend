using System.Text;
using Gml.WebApi.Core.Services;
using Gml.WebApi.Models.Dtos.Minecraft;
using Gml.WebApi.Models.Dtos.Profiles;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace Gml.WebApi.Core.Handlers;

public class MinecraftHandler
{
    public static async Task<IResult> GetProfileInfo(IGmlManager gmlManager, IAuthLibService authLibService,
        string uuid)
    {
        var profile = new Profile()
        {
            Id = uuid,
            Name = "GamerVII",
            Properties = []
        };

        var texture = new PropertyTextures
        {
            Timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            ProfileName = "GamerVII",
            ProfileId = uuid,
            Textures = new Textures
            {
                Skin = new SkinCape
                {
                    Url = "https://recloud.tech/GamerVII2.png"
                },
                Cape = new SkinCape
                {
                    Url = "https://recloud.tech/1052.png"
                }
            }
        };

        var base64Value = Convert.ToBase64String(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(texture)));
        var signature = await authLibService.GetSignature(base64Value);

        profile.Properties.Add(new ProfileProperties()
        {
            Value = base64Value,
            Signature = signature
        });

        return Results.Ok(profile);

        return Results.StatusCode(StatusCodes.Status204NoContent);
    }

    public static async Task<IResult> HasServerJoin(HttpContext context, IGmlManager gmlManager)
    {
        string username = context.Request.Query["username"].ToString();
        string serverId = context.Request.Query["serverId"].ToString();
        string ip = context.Request.Query["ip"].ToString();

        return Results.StatusCode(StatusCodes.Status204NoContent);
    }

    public static async Task<IResult> ServerJoin(IGmlManager gmlManager, ResponseServerJoin dto)
    {
        return Results.StatusCode(StatusCodes.Status204NoContent);
    }

    public static async Task<IResult> GetAuthLibMetaData(IGmlManager gmlManager, IAuthLibService authLibService)
    {
        return Results.Ok(new MetadataResponse
        {
            Meta = new MetaData
            {
                ServerName = "GamerVII LaunchServer",
                ImplementationVersion = "1.0.0"
            },
            SkinDomains = [".recloud.tech", "recloud.tech"],
            SignaturePublickey = await authLibService.GetPublicKey()
        });
    }
}
