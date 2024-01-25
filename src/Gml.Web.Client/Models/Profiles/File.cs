using Newtonsoft.Json;

namespace Gml.Web.Client.Models.Profiles;

public partial class File
{
    [JsonProperty("name")]
    public string Name { get; set; }

    [JsonProperty("directory")]
    public string Directory { get; set; }

    [JsonProperty("size")]
    public long Size { get; set; }

    [JsonProperty("hash")]
    public string Hash { get; set; }
}
