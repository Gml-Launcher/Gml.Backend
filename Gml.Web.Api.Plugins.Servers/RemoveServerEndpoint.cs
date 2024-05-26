using Gml.Web.Api.EndpointSDK;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Gml.Web.Api.Plugins.Servers;

[Path("DELETE", "/api/v1/plugins/servers", true)]
public class RemoveServerEndpoint : EndpointHelper, IPluginEndpoint
{
    public async Task Execute(HttpContext context, IGmlManager gmlManager)
    {
        var profileName = context.Request.Query["ProfileName"].FirstOrDefault();
        var serverName = context.Request.Query["ServerName"].FirstOrDefault();

        if (string.IsNullOrEmpty(profileName))
        {
            await BadRequest(context, $"Не предан обязательный атрибут \"ProfileName\"");
            return;
        }

        if (string.IsNullOrEmpty(serverName))
        {
            await BadRequest(context, $"Не предан обязательный атрибут \"ServerName\"");
            return;
        }

        var profile = await gmlManager.Profiles.GetProfile(profileName);

        if (profile is null)
        {
            await NotFound(context, $"Не удалось найти профиль с наименованием: \"{profileName}\"");
            return;
        }

        if (profile.Servers.All(c => c.Name != serverName))
        {
            await NotFound(context, $"Не удалось найти сервер с наименованием: \"{serverName}\"");
            return;
        }

        await gmlManager.Servers.RemoveServer(profile, serverName);

        await Ok(context, null, "Список успешно удален");
    }
}
