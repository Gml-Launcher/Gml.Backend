namespace Gml.Web.Client.Models.Profiles;

public class VersionInfo
{
    public VersionInfo(string name, string version)
    {
        Name = name;
        Value = version;
    }

    public string Name { get; set; }
    public string Value { get; set; }
}
