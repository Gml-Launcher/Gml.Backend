using System.Net;
using Gml.Core.User;
using Gml.Models.Auth;
using Gml.WebApi.Core.Services;
using Gml.WebApi.Models.Dtos.Auth;
using Gml.WebApi.Models.Dtos.Response;
using Gml.WebApi.Models.Dtos.Users;
using Gml.WebApi.Models.Enums.Auth;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.Authorization;

namespace Gml.WebApi.Core.Handlers;

public static class AuthHandler
{
    public static async Task<IResult> Auth( HttpContext context, IAuthService authService, IGmlManager manager, AuthDto authDto)
    {
        try
        {
            var authType = await manager.Integrations.GetAuthType();
            var userAgent = context.Request.Headers["User-Agent"].ToString();

            if (string.IsNullOrWhiteSpace(userAgent))
            {
                return Results.BadRequest(ResponseMessage.Create(
                    "Не удалось определить устройство, с которого произошла авторизация",
                    HttpStatusCode.BadRequest));
            }

            if (authType == AuthType.Undefined)
            {
                return Results.BadRequest(ResponseMessage.Create("Сервис авторизации не настроен",
                    HttpStatusCode.BadRequest));
            }

            if (await authService.CheckAuth(authDto.Login, authDto.Password, authType))
                return Results.Ok(ResponseMessage.Create(
                    await manager.Users.GetAuthData(authDto.Login, authDto.Password, userAgent), HttpStatusCode.OK,
                    string.Empty));
        }
        catch (HttpRequestException exception)
        {
            return Results.BadRequest(ResponseMessage.Create("Произошла ошибка при обмене данных с сервисом авторизации.", HttpStatusCode.InternalServerError));
        }
        catch (Exception exception)
        {
            return Results.BadRequest(ResponseMessage.Create(exception.Message, HttpStatusCode.InternalServerError));
        }

        return Results.BadRequest(ResponseMessage.Create("Неверный логин или пароль", HttpStatusCode.Unauthorized));
    }

    [Authorize]
    public static async Task<IResult> GetAuthServices(IAuthService authService, IGmlManager manager)
    {
        var authServices = await manager.Integrations.GetAuthServices();

        return Results.Ok(authServices.Select(c => new ReadIntegrationDto
        {
            Name = c.Name,
            AuthType = (int)c.AuthType
        }));
    }

    [Authorize]
    public static async Task<IResult> GetActiveAuthService(IAuthService authService, IGmlManager manager)
    {
        var authServices = await manager.Integrations.GetActiveAuthService();

        return Results.Ok(authServices);
    }

    [Authorize]
    public static async Task<IResult> UpdateActiveAuthService(IAuthService authService, IGmlManager manager,
        UpdateIntegrationDto updateDto)
    {
        if (!Enum.TryParse(updateDto.AuthType.ToString(), out AuthType authType))
            return Results.BadRequest();

        var service = await manager.Integrations.GetAuthService(authType);

        if (service == null)
        {
            service = (await manager.Integrations.GetAuthServices()).FirstOrDefault(c =>
                c.AuthType == authType); //ToDo: rewrite to Find
        }

        if (service == null)
        {
            return Results.NotFound();
        }

        service.Endpoint = updateDto.Endpoint;

        await manager.Integrations.SetActiveAuthService(service);

        return Results.Ok();
    }
}
