using System.Collections.Generic;
using System.Security.AccessControl;

namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class ProfileInfoReadDto
    {
        public string ProfileName { get; set; } = null!;
        public string MinecraftVersion { get; set; } = null!;
        public string ClientVersion { get; set; } = null!;
        public string Arguments { get; set; } = null!;
        public string JavaPath { get; set; } = null!;
        public List<LocalFileInfoDto> Files { get; set; } = null!;
        public List<LocalFileInfoDto> WhiteListFiles { get; set; } = null!;
    }
}
