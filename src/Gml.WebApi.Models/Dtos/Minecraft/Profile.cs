using System.Collections.Generic;
using Newtonsoft.Json;

namespace Gml.WebApi.Models.Dtos.Minecraft;

public class Profile
{
    [JsonProperty("id")] public string Id { get; set; }
    [JsonProperty("name")] public string Name { get; set; }
    [JsonProperty("properties")] public List<ProfileProperties> Properties { get; set; }
}

public class ProfileProperties
{
    [JsonProperty("name")] public string Name { get; } = "textures";
    [JsonProperty("value")] public string Value { get; set; }
    [JsonProperty("signature")] public string Signature { get; set; } = "Cg==";
}

public class PropertyTextures
{
    [JsonProperty("timestamp")] public long Timestamp { get; set; }
    [JsonProperty("profileId")] public string ProfileId { get; set; }
    [JsonProperty("profileName")] public string ProfileName { get; set; }
    [JsonProperty("textures")] public Textures Textures { get; set; }
}

public class Textures
{
    [JsonProperty("SKIN")] public SkinCape Skin { get; set; }
    [JsonProperty("CAPE")] public SkinCape Cape { get; set; }
}

public class SkinCape
{
    [JsonProperty("url")] public string Url { get; set; }
}
