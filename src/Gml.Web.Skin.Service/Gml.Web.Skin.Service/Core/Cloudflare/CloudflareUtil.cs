using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;

namespace Gml.Web.Skin.Service.Core.Cloudflare;

public class CloudflareUtil
{
    private const string _zoneId = "";
    private const string _accesToken = "";
    private const string _cacheUrl = "";
    private const bool _useHttps = true;
    private static readonly HttpClient httpClient = new();

    public static async Task ClearCacheAsync(params string[] urls)
    {
        try
        {
            const string apiUrl = $"https://api.cloudflare.com/client/v4/zones/{_zoneId}/purge_cache";
            var request = new HttpRequestMessage(HttpMethod.Post, apiUrl);

            request.Headers.Add("Authorization", $"Bearer {_accesToken}");
            request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            var paths = new JsonArray();
            foreach (var url in urls)
            {
                paths.Add($"http://{_cacheUrl}{url}");
                if (_useHttps)
                    paths.Add($"https://{_cacheUrl}{url}");
            }

            var json = new JsonObject();
            json.Add("files", paths);

            request.Content = new StringContent(json.ToString(), Encoding.UTF8, "application/json");

            var response = await httpClient.SendAsync(request);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                // ToDo: Добавить логгер
            }
        }
        catch (Exception ex)
        {
            // ToDo: Добавить логгер
        }
    }
}
