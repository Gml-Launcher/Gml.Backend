using Newtonsoft.Json;

namespace Gml.WebApi.Models.Dtos.Minecraft;

public class MetaData
{
    [JsonProperty("id")]
    public string ServerName { get; set; } = "Gml.Launcher";

    [JsonProperty("implementationName")]
    public string ImplementationName { get; set; } = "gml-launcher";

    [JsonProperty("implementationVersion")]
    public string ImplementationVersion { get; set; } = "1.0.1";

    [JsonProperty("feature.no_mojang_namespace")]
    public bool NoMojang { get; set; } = true;

    [JsonProperty("feature.privileges_api")]
    public bool PrivilegesApi { get; set; } = true;
}
