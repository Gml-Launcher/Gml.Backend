using Gml.Web.Skin.Service.Models.Dto;

namespace Gml.Web.Skin.Service.Models;

public class UserTexture
{
    public string UserName { get; set; } = null!;
    public bool HasCloak { get; set; }
    public bool HasSkin { get; set; }
    public string SkinUrl { get; set; } = null!;
    public string ClockUrl { get; set; } = null!;
    public string SkinFullPath { get; set; } = null!;
    public string? CloakFullPath { get; set; }
    public SkinPartialsDto Texture { get; set; } = null!;
    public SkinFormat SkinFormat { get; set; }
}
