using System.Text;
using CmlLib.Core.Downloader;

namespace Gml.WebApi.Core.Services;

public class FileService : IFileService
{
    private readonly string _privateKeyPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "private.key");
    private readonly string _publicKeyPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "public.key");

    private FileInfo PrivateKeyFileInfo => new(_privateKeyPath);
    private FileInfo PublicKeyFileInfo => new(_publicKeyPath);

    public async Task<string> LoadPrivateKey()
    {
        PrivateKeyFileInfo.Directory?.Create();

        if (!PublicKeyFileInfo.Exists)
            await DownloadFile("https://recloud.tech/private.key", _privateKeyPath);

        await using var fs = new FileStream(_privateKeyPath, FileMode.OpenOrCreate);
        using var sr = new StreamReader(fs, Encoding.UTF8);
        var data = await sr.ReadToEndAsync();

        if (!string.IsNullOrEmpty(data))
        {
            return data;
        }

        throw new KeyNotFoundException("Внимания, приватный ключ не найден, дальнейшая работа не возможна");
    }

    public async Task<string> LoadPublicKey()
    {
        PublicKeyFileInfo.Directory?.Create();

        if (!PublicKeyFileInfo.Exists)
            await DownloadFile("https://recloud.tech/public.key", _publicKeyPath);

        await using var fs = new FileStream(_publicKeyPath, FileMode.OpenOrCreate);
        using var sr = new StreamReader(fs, Encoding.UTF8);
        var data = await sr.ReadToEndAsync();

        if (!string.IsNullOrEmpty(data))
        {
            return data;
        }

        throw new KeyNotFoundException("Внимания, публичный ключ не найден, дальнейшая работа не возможна");
    }


    private static async Task DownloadFile(string url, string filePath)
    {
        using var httpClient = new HttpClient();
        var response = await httpClient.GetAsync(url);

        var content = await response.Content.ReadAsStringAsync();
        await File.WriteAllTextAsync(filePath, content);
    }
}
