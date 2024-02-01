using Gml.WebApi.Models.Enums.Auth;

namespace Gml.WebApi.Core.Services;

public interface IAuthService
{
    Task<bool> CheckAuth(string login, string password, AuthType authType);
}
