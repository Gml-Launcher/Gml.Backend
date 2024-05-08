using System.Threading.Tasks;
using Gml.Web.Api.EndpointSDK;
using Microsoft.AspNetCore.Http;

namespace Gml.Web.Api.Plugins.Template;

[Path("get", "/api/v1/plugins/template")]
public class TemplateEndpoint : IPluginEndpoint
{
    public async Task Execute(HttpContext context)
    {
        await context.Response.WriteAsync("template123123");
    }
}
