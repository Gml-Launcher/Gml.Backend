namespace Gml.WebApi.Models.Dtos.Profiles
{
    public class RemoveProfileDto
    {
        public string ClientName { get; set; } = null!;
        public bool RemoveFiles { get; set; }
    }
}
