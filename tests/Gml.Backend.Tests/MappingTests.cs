using Gml.Domains.Auth;
using Gml.Dto.Auth;
using Gml.Dto.Servers;
using Gml.Models.Servers;
using Gml.Web.Api.Domains.Servers;
using Gml.Web.Skin.Service.Models;
using Gml.Web.Skin.Service.Models.Dto;
using Mapster;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;

namespace Gml.Backend.Tests;

public class MappingTests
{
    private static ServiceProvider CreateServices(bool skinService = false)
    {
        var services = new ServiceCollection();
        if (skinService)
            Gml.Web.Skin.Service.Core.Extensions.Application.MappingExtensions.AddMapping(services);
        else
            Gml.Web.Api.Core.Extensions.MappingExtensions.AddMapping(services);
        return services.BuildServiceProvider();
    }

    [TestCase(false)]
    [TestCase(true)]
    public void AllRegisteredMappingsCompile(bool skinService)
    {
        using var services = CreateServices(skinService);
        Assert.DoesNotThrow(() => services.GetRequiredService<TypeAdapterConfig>().Compile());
    }

    [Test]
    public void ServerRequestAndResponsePreserveValues()
    {
        using var services = CreateServices();
        using var scope = services.CreateScope();
        var mapper = scope.ServiceProvider.GetRequiredService<IMapper>();
        var request = new CreateServerDto { Name = "Survival", Address = "play.example.com", Port = 25565 };
        var server = mapper.Map<MinecraftServer>(request);
        var response = mapper.Map<ServerReadDto>(server);

        Assert.Multiple(() =>
        {
            Assert.That(response.Name, Is.EqualTo(request.Name));
            Assert.That(server.Address, Is.EqualTo(request.Address));
            Assert.That(server.Port, Is.EqualTo(request.Port));
        });
    }

    [Test]
    public void RoleCollectionsMapFromRuntimeSourceType()
    {
        using var services = CreateServices();
        using var scope = services.CreateScope();
        var mapper = scope.ServiceProvider.GetRequiredService<IMapper>();
        object roles = new[] { new Role { Name = "Moderator", Description = "Moderates players" } };
        var response = mapper.Map<List<RoleDto>>(roles);

        Assert.That(response, Has.Count.EqualTo(1));
        Assert.That(response[0].Name, Is.EqualTo("Moderator"));
        Assert.That(response[0].Description, Is.EqualTo("Moderates players"));
    }

    [Test]
    public void TextureResponsePreservesNestedPartials()
    {
        using var services = CreateServices(skinService: true);
        using var scope = services.CreateScope();
        var mapper = scope.ServiceProvider.GetRequiredService<IMapper>();
        var texture = new UserTexture
        {
            UserName = "Player", HasSkin = true, HasCloak = true,
            SkinUrl = "/skin/Player", ClockUrl = "/cloak/Player",
            Texture = new SkinPartialsDto { Head = "/head/Player", Front = "/front/Player" }
        };
        var response = mapper.Map<UserTextureReadDto>(texture);

        Assert.Multiple(() =>
        {
            Assert.That(response.UserName, Is.EqualTo(texture.UserName));
            Assert.That(response.HasSkin, Is.True);
            Assert.That(response.HasCloak, Is.True);
            Assert.That(response.SkinUrl, Is.EqualTo(texture.SkinUrl));
            Assert.That(response.ClockUrl, Is.EqualTo(texture.ClockUrl));
            Assert.That(response.SkinFormat, Is.EqualTo(texture.SkinFormat));
            Assert.That(response.Texture.Head, Is.EqualTo(texture.Texture.Head));
            Assert.That(response.Texture.Front, Is.EqualTo(texture.Texture.Front));
        });
    }
}
