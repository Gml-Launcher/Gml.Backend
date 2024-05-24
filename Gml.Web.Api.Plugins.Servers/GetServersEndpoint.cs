using Gml.Web.Api.EndpointSDK;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Gml.Web.Api.Plugins.Servers;

[Path("GET", "/api/v1/plugins/servers", true)]
public class GetServersEndpoint : EndpointHelper, IPluginEndpoint
{
    public async Task Execute(HttpContext context, IGmlManager gmlManager)
    {
        var profileName = context.Request.Query["ProfileName"].FirstOrDefault();

        if (string.IsNullOrEmpty(profileName))
        {
            await BadRequest(context, $"Не предан обязательный атрибут \"ProfileName\"");
            return;
        }

        var profile = await gmlManager.Profiles.GetProfile(profileName);

        if (profile is null)
        {
            await NotFound(context, $"Не удалось найти профиль с наименованием: \"{profileName}\"");
            return;
        }

        var servers = profile.Servers;

        await Ok(context, servers, "Список серверов успешно получен");
    }
}
