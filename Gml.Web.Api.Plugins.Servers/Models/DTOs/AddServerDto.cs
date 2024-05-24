namespace Gml.Web.Api.Plugins.Servers.Models.DTOs;

public class AddServerDto
{
    public required string Name { get; set; }
    public required string Address { get; set; }
    public required int Port { get; set; }
    public required string ProfileName { get; set; }
}
