namespace Gml.Web.Skin.Service.Models.Dto;

public class UserTextureReadDto
{
    public string UserName { get; set; } = null!;
    public bool HasCloak { get; set; }
    public bool HasSkin { get; set; }
    public string SkinUrl { get; set; } = null!;
    public string ClockUrl { get; set; } = null!;
    public SkinPartialsDto Texture { get; set; } = null!;
    public SkinFormat SkinFormat { get; set; }
}
