using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace Gml.Web.Api.EndpointSDK;

public interface IPluginEndpoint
{
    Task Execute(HttpContext context);
}
