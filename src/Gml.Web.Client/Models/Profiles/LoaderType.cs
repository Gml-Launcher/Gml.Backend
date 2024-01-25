namespace Gml.Web.Client.Models.Profiles;


public class LoaderType
{
    public LoaderType(int value, string name)
    {
        Name = name;
        Value = value;
    }

    // Undefined = 0,
    // Vanilla = 1,
    // Forge = 2,
    public string Name { get; set; }
    public int Value { get; set; }
}
