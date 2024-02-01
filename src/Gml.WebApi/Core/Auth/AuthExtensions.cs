using Gml.WebApi.Core.Auth.Platforms;

namespace Gml.WebApi.Core.Auth;

public static class AuthExtensions
{
    public static IServiceCollection AddAuthIntegrations(this IServiceCollection serviceCollection)
    {
        serviceCollection.AddSingleton<IAuthServiceFactory, AuthServiceFactory>();

        serviceCollection.AddTransient<DataLifeEngineAuthService>();

        return serviceCollection;
    }
}
