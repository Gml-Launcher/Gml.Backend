namespace Gml.AdminPanel.Models.Hierarchy;

public class File
{
    public string Name { get; set; }
    public string Directory { get; set; }
    public long Size { get; set; }
    public string Hash { get; set; }
}

public class Folder
{
    public string Name { get; set; }
    public List<Folder> Subfolders { get; set; }
    public List<File> Files { get; set; }
}

public class Root
{
    public List<File> Files { get; set; }
    public List<Folder> Folders { get; set; }
}
