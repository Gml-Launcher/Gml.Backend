using System.Net;
using Gml.Web.Api.Domains.System;
using Gml.Web.Api.Dto.Messages;
using Gml.Web.Api.Dto.Profile;
using GmlCore.Interfaces;
using GmlCore.Interfaces.Enums;
using Microsoft.AspNetCore.Mvc.Testing;
using Newtonsoft.Json;

namespace Gml.WebApi.Tests;

public class Tests
{
    private WebApplicationFactory<Program> _webApplicationFactory;
    private IGmlManager _gmlManager;
    private HttpClient _httpClient;
    private string _profileName;

    [SetUp]
    public void Setup()
    {
        _webApplicationFactory = new GmlApiApplicationFactory();
        _httpClient = _webApplicationFactory.CreateClient();
    }

    [Test, Order(1)]
    public async Task RemoveAllProfilesEndFiles()
    {
        var httpClient = _webApplicationFactory.CreateClient();

        var response = await httpClient.GetAsync("/api/v1/profiles");

        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<List<ProfileReadDto>>>(content);

        foreach (var profile in model?.Data ?? Enumerable.Empty<ProfileReadDto>())
        {
            var deleteResponse = await httpClient.DeleteAsync($"/api/v1/profiles/{profile.Name}?removeFiles=true");

            Assert.That(deleteResponse.IsSuccessStatusCode, Is.True);
        }

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test, Order(2)]
    public async Task CreateProfile()
    {
        _profileName = Faker.Name.First();

        var profile = new MultipartFormDataContent();
        profile.Add(new StringContent(_profileName), "Name");
        profile.Add(new StringContent(Faker.Address.StreetAddress()), "Description");
        profile.Add(new StringContent("1.19.4"), "Version");
        profile.Add(new StringContent(((int)GameLoader.Forge).ToString()), "GameLoader");

        var response = await _httpClient.PostAsync("/api/v1/profiles", profile);

        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<ProfileReadDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data?.Name, Is.EqualTo(_profileName));
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.Created));
        });
    }

    [Test, Order(3)]
    public async Task GetProfileInfo()
    {

        var profile = TestHelper.CreateJsonObject(new ProfileCreateInfoDto
        {
            ProfileName = _profileName,
            GameAddress = "localhost",
            GamePort = 25565,
            RamSize = 4096,
            WindowWidth = 900,
            WindowHeight = 600,
            IsFullScreen = true,
            OsType = ((int)OsType.Windows).ToString(),
            OsArchitecture = Environment.Is64BitOperatingSystem ? "64" : "32",
            UserAccessToken = "sergsecgrfsecgriseuhcygrshecngrysicugrbn7csewgrfcsercgser",
            UserName = "GamerVII",
            UserUuid = "userUuid"
        });

        var response = await _httpClient.PostAsync("/api/v1/profiles/info", profile);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<ProfileReadInfoDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
            Assert.That(model?.Data?.ProfileName, Is.Not.Empty);
            Assert.That(model?.Data?.ProfileName, Is.EqualTo(_profileName));
        });
    }

    [Test, Order(4)]
    public async Task CompileProfile()
    {
        var profile = TestHelper.CreateJsonObject(new ProfileCompileDto
        {
            Name = _profileName,
        });

        var response = await _httpClient.PostAsync("/api/v1/profiles/compile", profile);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<ProfileReadInfoDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
        });
    }

}
