using System.Net;
using Faker;
using Gml.Web.Api.Domains.LauncherDto;
using Gml.Web.Api.Domains.System;
using Gml.Web.Api.Dto.Launcher;
using Gml.Web.Api.Dto.Messages;
using Gml.Web.Api.Dto.Profile;
using Gml.Web.Api.Dto.Settings;
using Gml.Web.Api.Dto.Texture;
using GmlCore.Interfaces.Enums;
using Microsoft.AspNetCore.Mvc.Testing;
using Newtonsoft.Json;

namespace Gml.WebApi.Tests;

public class Tests
{
    private readonly string _newSenryUrl = "https://sentry.test.ru";
    private readonly string _newTextureUrl = "https://test.ru";
    private readonly string _profileName = Name.First();
    private HttpClient _httpClient;
    private WebApplicationFactory<Program> _webApplicationFactory;

    [SetUp]
    public void Setup()
    {
        _webApplicationFactory = new GmlApiApplicationFactory();
        _httpClient = _webApplicationFactory.CreateClient();
    }

    [Test]
    [Order(1)]
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

    [Test]
    [Order(2)]
    public async Task CreateProfile()
    {
        var profile = new MultipartFormDataContent();
        profile.Add(new StringContent(_profileName), "Name");
        profile.Add(new StringContent(Address.StreetAddress()), "Description");
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

    [Test]
    [Order(3)]
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
            UserAccessToken = "accessToken",
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

    [Test]
    [Order(4)]
    public async Task UpdateProfile()
    {
        var profileUpdateData = new MultipartFormDataContent
        {
            { new StringContent(_profileName), "Name" },
            { new StringContent(_profileName), "OriginalName" },
            { new StringContent("Avon"), "Description" },
            { new StringContent("image"), "IconBase64" }
        };

        var response = await _httpClient.PutAsync("/api/v1/profiles", profileUpdateData);

        var content = await response.Content.ReadAsStringAsync();
        var model = JsonConvert.DeserializeObject<ResponseMessage<SettingsReadDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
        });
    }

    [Test]
    [Order(5)]
    public async Task CompileProfile()
    {
        var profile = TestHelper.CreateJsonObject(new ProfileCompileDto
        {
            Name = _profileName
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

    [Test]
    [Order(6)]
    public async Task GetSettings()
    {
        var response = await _httpClient.GetAsync("/api/v1/settings/platform");
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<SettingsReadDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
        });
    }

    [Test]
    [Order(7)]
    public async Task UpdateSettings()
    {
        var httpContent = TestHelper.CreateJsonObject(new SettingsUpdateDto
        {
            RegistrationIsEnabled = true
        });

        var response = await _httpClient.PutAsync("/api/v1/settings/platform", httpContent);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<SettingsReadDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
        });
    }

    [Test]
    [Order(8)]
    public async Task UpdateSkinsUrl()
    {
        var httpContent = TestHelper.CreateJsonObject(new UrlServiceDto(_newTextureUrl));

        var response = await _httpClient.PutAsync("/api/v1/integrations/texture/skins", httpContent);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.IsTrue(response.IsSuccessStatusCode);
        });
    }

    [Test]
    [Order(9)]
    public async Task UpdateCloaksUrl()
    {
        var httpContent = TestHelper.CreateJsonObject(new UrlServiceDto(_newTextureUrl));

        var response = await _httpClient.PutAsync("/api/v1/integrations/texture/cloaks", httpContent);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(10)]
    public async Task GetSkinsUrl()
    {
        var response = await _httpClient.GetAsync("/api/v1/integrations/texture/skins");
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data, Is.Not.Null);
            Assert.That(model?.Data?.Url, Is.EqualTo(_newTextureUrl));
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(11)]
    public async Task GetCloaksUrl()
    {
        var response = await _httpClient.GetAsync("/api/v1/integrations/texture/cloaks");
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data, Is.Not.Null);
            Assert.That(model?.Data?.Url, Is.EqualTo(_newTextureUrl));
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(12)]
    public async Task UpdateSentryDsn()
    {
        var httpContent = TestHelper.CreateJsonObject(new UrlServiceDto(_newSenryUrl));

        var response = await _httpClient.PutAsync("/api/v1/integrations/sentry/dsn", httpContent);
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(13)]
    public async Task GetSentryDsn()
    {
        var response = await _httpClient.GetAsync("/api/v1/integrations/sentry/dsn");
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<UrlServiceDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data, Is.Not.Null);
            Assert.That(model?.Data?.Url, Is.EqualTo(_newSenryUrl));
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(14)]
    public async Task GetLauncherVersions()
    {
        var response = await _httpClient.GetAsync("/api/v1/integrations/github/launcher/versions");
        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<List<LauncherVersionReadDto>>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data, Is.Not.Null);
            Assert.That(model?.Data?.Any(), Is.True);
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }

    [Test]
    [Order(15)]
    public async Task CompileLauncherVersions()
    {
        var httpContent = TestHelper.CreateJsonObject(new LauncherCreateDto
        {
            GitHubVersions = "master",
            Host = "https://localhost:5000",
            Folder = "GmlLauncher"
        });

        var response = await _httpClient.PostAsync("/api/v1/integrations/github/launcher/download", httpContent);
        var content = await response.Content.ReadAsStringAsync();

        Assert.Multiple(() =>
        {
            Assert.That(response.IsSuccessStatusCode, Is.True);
            Assert.That(string.IsNullOrWhiteSpace(content), Is.False);
        });
    }

    [Test]
    [Order(16)]
    public async Task DownloadLauncherVersions()
    {
        var response = await _httpClient.GetAsync("/api/v1/integrations/github/launcher/download/master");
        var content = await response.Content.ReadAsStringAsync();

        Assert.Multiple(() =>
        {
            Assert.That(string.IsNullOrWhiteSpace(content), Is.False);
            Assert.That(response.IsSuccessStatusCode, Is.True);
        });
    }
}
