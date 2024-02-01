using Gml.WebApi.Core.Auth.Platforms;
using Gml.WebApi.Models.Enums.Auth;

namespace Gml.WebApi.Core.Auth;

public class AuthServiceFactory(IServiceProvider serviceProvider) : IAuthServiceFactory
{
    public IPlatformAuthService CreateAuthService(AuthType platformKey)
    {

        switch (platformKey)
        {
            case AuthType.Undefined:
                break;
            case AuthType.DataLifeEngine:
                return serviceProvider.GetRequiredService<DataLifeEngineAuthService>();
            default:
                throw new ArgumentOutOfRangeException(nameof(platformKey), platformKey, null);
        }

        throw new ArgumentOutOfRangeException(nameof(platformKey), platformKey, null);
    }
}
