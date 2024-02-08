using AutoMapper;
using Gml.Web.Skin.Service.Models;
using Gml.Web.Skin.Service.Models.Dto;

namespace Gml.Web.Skin.Service.Core.Mapper;

public class TextureMapper : Profile
{
    public TextureMapper()
    {
        CreateMap<UserTexture, UserTextureReadDto>();
    }
}
