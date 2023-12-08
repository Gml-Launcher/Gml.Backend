using Gml.WebApi.Core.Extensions;

WebApplication
    .CreateBuilder(args)
    .RegisterServices()
    .Build()
    .RegisterRoutes()
    .AddMiddlewares()
    .Run();