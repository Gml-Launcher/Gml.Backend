using Gml.WebApi.Core.Auth;
using Gml.WebApi.Models.Enums.Auth;

namespace Gml.WebApi.Core.Services;

public class AuthService(IAuthServiceFactory authServiceFactory) : IAuthService
{
    public Task<bool> CheckAuth(string login, string password, AuthType authType)
    {
        var authService = authServiceFactory.CreateAuthService(authType);

        return authService.Auth(login, password);
    }
}
