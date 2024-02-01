namespace Gml.WebApi.Models.Dtos.Auth
{
    public class ReadIntegrationDto
    {
        public string Name { get; set; } = null!;
        public string Endpoint { get; set; } = null!;
        public int AuthType { get; set; }
    }
}
