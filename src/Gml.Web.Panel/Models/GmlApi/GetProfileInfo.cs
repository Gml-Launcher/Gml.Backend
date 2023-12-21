using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Gml.AdminPanel.Models.GmlApi
{
    public partial class GetProfileInfo
    {
        [JsonPropertyName("profileName")]
        public string ProfileName { get; set; }

        [JsonPropertyName("minecraftVersion")]
        public string MinecraftVersion { get; set; }

        [JsonPropertyName("clientVersion")]
        public string ClientVersion { get; set; }

        [JsonPropertyName("arguments")]
        public string Arguments { get; set; }

        [JsonPropertyName("files")]
        public IEnumerable<File> Files { get; set; }

        [JsonPropertyName("whiteListFiles")]
        public IEnumerable<string> WhiteListFiles { get; set; }
    }
}
