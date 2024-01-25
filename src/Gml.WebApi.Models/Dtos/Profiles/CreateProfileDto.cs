namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class CreateProfileDto
    {
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string Version { get; set; } = null!;
        public int GameLoader { get; set; }
        public string IconBase64 { get; set; } = null!;
    }

}
