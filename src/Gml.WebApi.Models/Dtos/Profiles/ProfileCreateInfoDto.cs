using Gml.WebApi.Models.Enums.System;

namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class ProfileCreateInfoDto
    {
        public string UserName { get; set; } = null!;
        public string UserAccessToken { get; set; } = null!;
        public string ClientName { get; set; } = null!;
        public int SizeX { get; set; }
        public int SizeY { get; set; }
        public string? GameAddress { get; set; }
        public int GamePort { get; set; }
        public bool IsFullScreen { get; set; }
        public int RamSize { get; set; }
        public string UserUuid { get; set; } = null!;
        public int OsType { get; set; }
        public string OsArchitecture { get; set; } = null!;
    }

}
