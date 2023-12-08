namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class ProfileCreateInfoDto
    {

        public string UserName { get; set; }
        public string UserAccessToken { get; set; }
        public string ClientName { get; set; }
        public int SizeX { get; set; }
        public int SizeY { get; set; }
        public string? GameAddress { get; set; }
        public int GamePort { get; set; }
        public bool IsFullScreen { get; set; }
        public int RamSize { get; set; }
        public string UserUuid { get; set; }
    }

}