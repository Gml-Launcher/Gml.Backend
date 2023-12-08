using System.Collections.Generic;
using System.Security.AccessControl;

namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class ProfileInfoReadDto
    {
        public string ProfileName { get; set; }
        public string MinecraftVersion { get; set; }
        public string ClientVersion { get; set; }
        public string Arguments { get; set; }
        public IEnumerable<LocalFileInfoDto> Files { get; set; }
        public IEnumerable<LocalFileInfoDto> WhiteListFiles { get; set; }
    }

}