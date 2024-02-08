using Newtonsoft.Json;

namespace Gml.WebApi.Models.Dtos.Minecraft;

public class MetadataResponse
{
    [JsonProperty("meta")]
    public MetaData Meta { get; set; } = new();

    [JsonProperty("skinDomains")]
    public string[] SkinDomains { get; set; }

    [JsonProperty("signaturePublickey")]
    public string SignaturePublickey { get; set; }
}
