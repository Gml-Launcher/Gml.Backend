namespace Gml.WebApi.Core.Auth.Platforms;

public interface IPlatformAuthService
{
    Task<bool> Auth(string login, string password);
}
