using System.Text;
using Gml.Web.Api.Dto.Profile;
using Microsoft.Net.Http.Headers;
using Newtonsoft.Json;

namespace Gml.WebApi.Tests;

public class TestHelper
{
    public static HttpContent CreateJsonObject(object body)
    {
        var content = JsonConvert.SerializeObject(body);

        return new StringContent(content, Encoding.UTF8, "application/json");
    }
}
