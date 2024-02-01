namespace Gml.WebApi.Config;

public class Auth
{
    public required string Endpoint { get; set; }
}

public class ProjectSettings
{
    public required string ProjectName { get; set; }
    public required string ProjectPath { get; set; }
    public required Auth Auth { get; set; }
}
