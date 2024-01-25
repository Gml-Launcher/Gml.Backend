namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class LocalFileInfoDto
    {
        public string Name { get; set; } = null!;
        public string Directory { get; set; } = null!;
        public long Size { get; set; }
        public string Hash { get; set; } = null!;
    }
}
