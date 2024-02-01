namespace Gml.WebApi.Models.Dtos.Auth
{
    public class UpdateIntegrationDto
    {
        public int AuthType { get; set; }
        public string Endpoint { get; set; } = null!;
    }
}
