using System.IO.Compression;
using System.Text;
using Newtonsoft.Json;

namespace Gml.Backend.Tests;

public class TestHelper
{
    public static HttpContent CreateJsonObject(object body)
    {
        var content = JsonConvert.SerializeObject(body);

        return new StringContent(content, Encoding.UTF8, "application/json");
    }

    public static async Task<FileInfo[]> GetFilesFolder(string path)
    {
        var directory = new DirectoryInfo(path);

        return directory.GetFiles("*", SearchOption.AllDirectories);
    }

    public static async Task<string> DownloadGithubProject(string projectPath, string projectUser, string projectName, string branchName, bool isTags = true)
    {
        var directory = new DirectoryInfo(projectPath);

        if (!directory.Exists) directory.Create();

        var zipPath = $"{projectPath}/{projectName}.zip";
        var extractPath = NormalizePath(projectPath, projectName);

        var url = $"https://github.com/{projectUser}/{projectName}/archive/refs/{(isTags ? "tags" : "heads")}/{branchName}.zip";

        using (var client = new HttpClient())
        {
            var stream = await client.GetStreamAsync(url);

            await using (var fileStream = new FileStream(zipPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                await stream.CopyToAsync(fileStream);
            }
        }

        // Проверяем, существует ли уже папка для распаковки
        if (!Directory.Exists(extractPath))
            // Если папка не существует - создаем ее
            Directory.CreateDirectory(extractPath);

        // Распаковываем архив во временную директорию
        string tempExtractPath = $"{extractPath}_temp";
        ZipFile.ExtractToDirectory(zipPath, tempExtractPath, true);

        // Перемещаем файлы и папки из вложенной папки в основную
        var tempDirectoryInfo = new DirectoryInfo(tempExtractPath).GetDirectories().First();

        foreach (var file in tempDirectoryInfo.GetFiles())
        {
            file.MoveTo(Path.Combine(extractPath, file.Name));
        }
        foreach (var dir in tempDirectoryInfo.GetDirectories())
        {
            dir.MoveTo(Path.Combine(extractPath, dir.Name));
        }

        // Удаляем временную директорию
        Directory.Delete(tempExtractPath, true);

        File.Delete(zipPath);

        return new DirectoryInfo(extractPath).GetDirectories().First().FullName;
    }

    private static string NormalizePath(string directory, string fileDirectory)
    {
        directory = directory
            .Replace('\\', Path.DirectorySeparatorChar)
            .Replace('/', Path.DirectorySeparatorChar);
        // .TrimStart(Path.DirectorySeparatorChar);

        fileDirectory = fileDirectory
            .Replace('\\', Path.DirectorySeparatorChar)
            .Replace('/', Path.DirectorySeparatorChar)
            .TrimStart(Path.DirectorySeparatorChar);

        return Path.Combine(directory, fileDirectory);
    }
}
