using System.Security.Cryptography;
using System.Text;

namespace Gml.WebApi.Core.Services;

public class AuthLibService : IAuthLibService
{
    public string PrivateKey;
    public string PublicKey;

    IFileService files;

    public AuthLibService(IFileService _files)
    {
        files = _files;
    }

    public async Task<string> GetSignature(string data)
    {
        PrivateKey = await files.LoadPrivateKey();

        RSACryptoServiceProvider csp = new RSACryptoServiceProvider(4096);
        csp.ImportFromPem(PrivateKey);

        byte[] inputBytes = Encoding.UTF8.GetBytes(data);
        byte[] signatureBytes = csp.SignData(inputBytes, "SHA1");
        return Convert.ToBase64String(signatureBytes);
    }
    public async Task<string> GetPublicKey()
    {
        PublicKey = await files.LoadPublicKey();
        return PublicKey;
    }
}
