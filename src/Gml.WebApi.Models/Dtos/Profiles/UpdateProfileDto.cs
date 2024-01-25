namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class UpdateProfileDto
    {
        public string OriginalName { get; set; } = null!;
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string IconBase64 { get; set; } = null!;
    }

}
