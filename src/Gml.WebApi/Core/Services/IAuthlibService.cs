namespace Gml.WebApi.Core.Services;

public interface IAuthLibService
{
    Task<string> GetSignature(string data);
    Task<string> GetPublicKey();
}
