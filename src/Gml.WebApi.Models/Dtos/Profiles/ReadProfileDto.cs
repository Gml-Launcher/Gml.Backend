using System;

namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class ReadProfileDto
    {
        public string Name { get; set; } = null!;
        public string GameVersion { get; set; } = null!;
        public string LaunchVersion { get; set; } = null!;
        public string Description { get; set; }
        public DateTimeOffset? CreateDate { get; set; }
        public string? IconBase64 { get; set; }
    }
}
