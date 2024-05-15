using FluentValidation;
using FluentValidation.Results;
using Gml.Web.Api.EndpointSDK;
using Gml.Web.Api.Plugins.Servers.Models.DTOs;
using Gml.Web.Api.Plugins.Servers.Validators;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Gml.Web.Api.Plugins.Servers;

[Path("POST", "/api/v1/plugins/servers", true)]
public class AddServerEndpoint : EndpointHelper, IPluginEndpoint
{
    public async Task Execute(HttpContext context, IGmlManager gmlManager)
    {
        try
        {
            var serverDto = await ParseDto<AddServerDto>(context);

            if (!IsValidDto<AddServerDto, ServerCreateValidator>(serverDto, out var errors))
            {
                await BadRequest(context, errors.Errors, "Ошибка валидации");
            }

            var profile = await gmlManager.Profiles.GetProfile(serverDto!.ProfileName);

            if (profile is null)
            {
                await NotFound(context, $"Не удалось найти профиль с наименованием: \"{serverDto.ProfileName}\"");
                return;
            }

            var server =
                await gmlManager.Servers.AddMinecraftServer(profile, serverDto.Name, serverDto.Address, serverDto.Port);

            await Created(context, server, "Сервер был успешно создан");
        }
        catch (Exception exception)
        {
            await BadRequest(context, exception.Message);
        }
    }
}
