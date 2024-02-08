namespace Gml.WebApi.Core.Services;

public interface IFileService
{
    Task<string> LoadPrivateKey();
    Task<string> LoadPublicKey();
}
