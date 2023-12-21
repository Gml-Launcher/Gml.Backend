using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Gml.AdminPanel.Models.GmlApi
{
    public partial class GetProfileDto
    {
        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("gameVersion")]
        public string GameVersion { get; set; }

        [JsonPropertyName("launchVersion")]
        public string LaunchVersion { get; set; }
    }
}
