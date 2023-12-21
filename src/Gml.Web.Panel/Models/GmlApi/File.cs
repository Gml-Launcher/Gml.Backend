using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace GmlAdminPanel.Models.GmlApi
{
    public partial class File
    {
        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("directory")]
        public string Directory { get; set; }

        [JsonPropertyName("size")]
        public long Size { get; set; }

        [JsonPropertyName("hash")]
        public string Hash { get; set; }
    }
}
