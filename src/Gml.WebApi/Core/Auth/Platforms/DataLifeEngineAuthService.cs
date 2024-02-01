using System.Net.Http.Headers;
using System.Text;
using Gml.WebApi.Config;
using GmlCore.Interfaces;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;

namespace Gml.WebApi.Core.Auth.Platforms;

public class DataLifeEngineAuthService(IHttpClientFactory httpClientFactory, IGmlManager gmlManager) : IPlatformAuthService
{
    private readonly HttpClient _httpClient = httpClientFactory.CreateClient();
    private readonly IGmlManager _gmlManager = gmlManager;

    public async Task<bool> Auth(string login, string password)
    {
        var dto = JsonConvert.SerializeObject(new
        {
            Login = login,
            Password = password
        });

        var content = new StringContent(dto, Encoding.UTF8, MediaTypeHeaderValue.Parse("application/json"));

        var result = await _httpClient.PostAsync((await _gmlManager.Integrations.GetActiveAuthService())!.Endpoint, content);

        return result.IsSuccessStatusCode;
    }
}
