using Gml.WebApi.Core.Auth.Platforms;
using Gml.WebApi.Models.Enums.Auth;

namespace Gml.WebApi.Core.Auth;

public interface IAuthServiceFactory
{
    IPlatformAuthService CreateAuthService(AuthType platformKey);
}
