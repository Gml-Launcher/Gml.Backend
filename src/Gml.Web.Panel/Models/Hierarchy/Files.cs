namespace GmlAdminPanel.Models.Hierarchy;

public class FileNode : Node
{
    public GmlApi.File CurrentFile { get; set; }
}

public class FolderNode : Node
{

}

public class Node
{
    public string Name { get; set; }
    public string Directory { get; set; }
    public long Size { get; set; }
    public string Hash { get; set; }
    public Node Parent { get; set; }
    public List<FileNode> Files { get; set; }
    public List<FolderNode> Folders { get; set; }

    public string GetHierarchyPath(Node node)
    {
        if (node == null)
            return string.Empty;

        if (node.Parent == null)
            return node.Directory;

        return string.Concat(GetHierarchyPath(node.Parent), "/", node.Directory);
    }
}
