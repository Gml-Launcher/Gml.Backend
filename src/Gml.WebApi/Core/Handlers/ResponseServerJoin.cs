using Newtonsoft.Json;

namespace Gml.WebApi.Core.Handlers;

public class ResponseServerJoin
{
    [JsonProperty("accessToken")] public string AccessToken { get; set; }

    [JsonProperty("selectedProfile")] public string SelectedProfile { get; set; }

    [JsonProperty("serverId")] public string ServerId { get; set; }
}
