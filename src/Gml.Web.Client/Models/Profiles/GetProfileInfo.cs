using Newtonsoft.Json;

namespace Gml.Web.Client.Models.Profiles;

public class GetProfileInfo
{
    [JsonProperty("profileName")]
    public string ProfileName { get; set; }
    [JsonProperty("iconBase64")]
    public string IconBase64 { get; set; }

    [JsonProperty("minecraftVersion")]
    public string MinecraftVersion { get; set; }

    [JsonProperty("clientVersion")]
    public string ClientVersion { get; set; }

    [JsonProperty("description")]
    public string Description { get; set; }

    [JsonProperty("arguments")]
    public string Arguments { get; set; }

    [JsonProperty("files")]
    public IEnumerable<File> Files { get; set; }

    [JsonProperty("whiteListFiles")]
    public IEnumerable<File> WhiteListFiles { get; set; }
}
