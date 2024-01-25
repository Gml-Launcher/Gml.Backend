namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class PackProfileDto
    {
        public PackProfileDto(string name)
        {
            Name = name;
        }

        public string Name { get; set; }
    }
}
