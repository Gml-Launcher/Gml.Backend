using Gml.Web.Skin.Service.Models;
using Gml.Web.Skin.Service.Models.Dto;

namespace Gml.Web.Skin.Service;

public abstract class SkinHelper
{
    private const string DefaultSkinName = "default.png";

    public static string SkinTextureDirectory { get; } =
        Path.Combine(Environment.CurrentDirectory, "Storage", "Skins");

    public static string CloakTextureDirectory { get; } =
        Path.Combine(Environment.CurrentDirectory, "Storage", "Cloak");

    public static UserTexture Create(string requestPathBase, string userName)
    {
        var skinPath = Path.Combine(SkinTextureDirectory, $"{userName}.png");
        var cloakPath = Path.Combine(CloakTextureDirectory, $"{userName}.png");

        if (!File.Exists(skinPath))
            skinPath = Path.Combine(SkinTextureDirectory, DefaultSkinName);

        if (!File.Exists(cloakPath))
            cloakPath = string.Empty;

        var texture = new UserTexture
        {
            UserName = userName,
            HasSkin = !skinPath.EndsWith(DefaultSkinName),
            HasCloak = !string.IsNullOrEmpty(cloakPath),
            SkinUrl = $"{requestPathBase}/skin/{userName}",
            SkinFullPath = skinPath.EndsWith(DefaultSkinName)
                ? Path.Combine(Environment.CurrentDirectory, SkinTextureDirectory, "default.png")
                : Path.Combine(Environment.CurrentDirectory, SkinTextureDirectory, $"{userName}.png"),
            CloakFullPath = string.IsNullOrEmpty(cloakPath)
                ? string.Empty
                : Path.Combine(Environment.CurrentDirectory, CloakTextureDirectory, $"{userName}.png"),
            ClockUrl = $"{requestPathBase}/cloak/{userName}",
            Texture = new SkinPartialsDto
            {
                Head = $"{requestPathBase}/skin/{userName}/head/128",
                Front = $"{requestPathBase}/skin/{userName}/front/128",
                Back = $"{requestPathBase}/skin/{userName}/back/128",
                CloakBack = $"{requestPathBase}/skin/{userName}/full-back/128",
                Cloak = $"{requestPathBase}/cloak/{userName}/128"
            }
        };

        if (!texture.HasSkin) return texture;
        using var inputImage = Image.Load(texture.SkinFullPath);

        texture.SkinFormat = GetSkinFormat(inputImage.Width);

        inputImage.Dispose();

        return texture;
    }

    private static SkinFormat GetSkinFormat(double width)
    {
        return width switch
        {
            > 64 and < 1024 => SkinFormat.SkinHD,
            > 512 => SkinFormat.SkinFullHD,
            _ => SkinFormat.SkinSD
        };
    }

    public static string GetActualSkinPath(string userName, UserTexture user)
    {
        var imagePath = Path.Combine(SkinTextureDirectory, $"{userName}.png");

        if (!user.HasSkin) imagePath = Path.Combine(SkinTextureDirectory, "default.png");

        return imagePath;
    }
}
