using System.Diagnostics;
using System.Net;
using System.Text;
using Faker;
using Gml.Core.Launcher;
using Gml.Web.Api.Domains.LauncherDto;
using Gml.Web.Api.Dto.Integration;
using Gml.Web.Api.Dto.Launcher;
using Gml.Web.Api.Dto.Messages;
using Gml.Web.Api.Dto.Profile;
using Gml.Web.Api.Dto.Texture;
using Gml.Web.Api.Dto.User;
using GmlCore.Interfaces.Enums;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.SignalR.Client;
using Newtonsoft.Json;

namespace Gml.Backend.Tests;

public class Tests
{
    private GmlManager GmlManager { get; } =
        new(new GmlSettings("GamerVIILauncher", "gfweagertghuysergfbsuyerbgiuyserg", httpClient: new HttpClient())
        {
            TextureServiceEndpoint = "http://gml-web-skins:8085"
        });

    private HttpClient _httpClient;
    private WebApplicationFactory<Program> _webApplicationFactory;
    private readonly string _profileName = "UnitTestProfile";
    private readonly string _newTextureUrl = "https://test.ru";

    private HubConnection _profileHub;
    private HubConnection _launcherHub;

    [SetUp]
    public void Setup()
    {
        Environment.SetEnvironmentVariable("SECURITY_KEY", "jkuhbsfgvuk4gfikhn8i7wa34rkbqw23");
        Environment.SetEnvironmentVariable("PROJECT_NAME", "GmlServer");
        Environment.SetEnvironmentVariable("MARKET_ENDPOINT", "https://gml-market.recloud.tech");
        Environment.SetEnvironmentVariable("PROJECT_DESCRIPTION", "GmlServer Description");
        Environment.SetEnvironmentVariable("PROJECT_POLICYNAME", "GmlPolicy");
        Environment.SetEnvironmentVariable("PROJECT_PATH", "");
        Environment.SetEnvironmentVariable("SERVICE_TEXTURE_ENDPOINT", "http://gml-web-skins:8085");
        Environment.SetEnvironmentVariable("DOTNET_HOST_FACTORY_RESOLVER_DEFAULT_TIMEOUT_IN_SECONDS", "100");

        _webApplicationFactory = new GmlApiApplicationFactory();
        _httpClient = _webApplicationFactory.CreateClient();

        _profileHub = new HubConnectionBuilder()
            .WithUrl($"{_httpClient.BaseAddress}ws/profiles/restore", options =>
            {
                options.HttpMessageHandlerFactory = _ => _webApplicationFactory.Server.CreateHandler();
            })
            .Build();

        _launcherHub = new HubConnectionBuilder()
            .WithUrl($"{_httpClient.BaseAddress}ws/launcher/build", options =>
            {
                options.HttpMessageHandlerFactory = _ => _webApplicationFactory.Server.CreateHandler();
            })
            .Build();
    }

    [TearDown]
    public async Task TearDown()
    {
        _httpClient.Dispose();
        await _webApplicationFactory.DisposeAsync();
    }

    [Test]
    [Order(1)]
    public async Task RemoveAllProfilesEndFiles()
    {
        var response = await _httpClient.GetAsync("/api/v1/profiles");

        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<List<ProfileReadDto>>>(content);

        foreach (var profile in model?.Data ?? Enumerable.Empty<ProfileReadDto>())
        {
            var deleteResponse = await _httpClient.DeleteAsync($"/api/v1/profiles/{profile.Name}?removeFiles=true");

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
    public async Task CreateProfileTest()
    {
        var profile = new MultipartFormDataContent();
        profile.Add(new StringContent(_profileName), "Name");
        profile.Add(new StringContent(_profileName), "DisplayName");
        profile.Add(new StringContent(Address.StreetAddress()), "Description");
        profile.Add(new StringContent("1.7.10"), "Version");
        profile.Add(new StringContent(((int)GameLoader.Forge).ToString()), "GameLoader");
        profile.Add(new StringContent("10.13.4.1614"), "LoaderVersion");

        var response = await _httpClient.PostAsync("/api/v1/profiles", profile);

        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage<ProfileReadDto>>(content);

        Assert.Multiple(() =>
        {
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.Created));
            Assert.That(model, Is.Not.Null);
            Assert.That(model?.Data?.Name, Is.EqualTo(_profileName));
        });
    }

    [Test]
    [Order(3)]
    public async Task RestoreProfileTest()
    {
        // if (_profileHub.State != HubConnectionState.Connected)
        //     await _profileHub.StartAsync();
        //
        // var messageReceived = new TaskCompletionSource<string>();
        //
        // // await _profileHub.SendCoreAsync("Restore", [_profileName]);
        //
        // _profileHub.On<string, string>("Log", (profileName, message) =>
        // {
        //     Debug.WriteLine($"Profile name: {profileName}\nMessage: {message}");
        // });
        //
        // _profileHub.On<string>("SuccessInstalled", (profileName) =>
        // {
        //     messageReceived.SetResult($"Restore Profile Success. Profile name: {profileName}");
        // });
        //
        // var message = await messageReceived.Task;
        //
        // // Assert.Multiple(() =>
        // // {
        // //     Assert.That(message, Is.Not.Null);
        // // });
    }

    [Test]
    [Order(4)]
    public async Task CompileProfileTest()
    {
        if (_profileHub.State != HubConnectionState.Connected)
            await _profileHub.StartAsync();

        var messageReceived = new TaskCompletionSource<string>();

        await _profileHub.SendCoreAsync("Build", [_profileName]);

        _profileHub.On<string, string>("Log", (profileName, message) =>
        {
            Debug.WriteLine($"Profile name: {profileName}\nMessage: {message}");
        });

        _profileHub.On<string>("SuccessPacked", (profileName) =>
        {
            messageReceived.SetResult($"Packaging Profile Success. Profile name: {profileName}");
        });

        var message = await messageReceived.Task;

        Assert.Multiple(() =>
        {
            Assert.That(message, Is.Not.Null);
        });
    }

    [Test]
    [Order(5)]
    public async Task DownloadLauncherTest()
    {
        if (_launcherHub.State != HubConnectionState.Connected)
            await _launcherHub.StartAsync();

        var response = await _httpClient.GetAsync("api/v1/integrations/github/launcher/versions");

        if (response.StatusCode != HttpStatusCode.OK)
            Assert.Fail();

        var versions = JsonConvert.DeserializeObject<ResponseMessage<List<LauncherVersionReadDto>>>(await response.Content.ReadAsStringAsync());

        var messageReceived = new TaskCompletionSource<string>();

        await _launcherHub.SendCoreAsync("Download", [versions.Data[0].Version, _httpClient.BaseAddress, _profileName]);

        _launcherHub.On("LauncherDownloadEnded", () =>
        {
            messageReceived.SetResult("Download Launcher Success.");
        });

        var message = await messageReceived.Task;

        Assert.Multiple(() =>
        {
            Assert.That(message, Is.Not.Null);
        });
    }

    [Test]
    [Order(6)]
    public async Task DownloadLibLauncherTest()
    {
        // var response = await _httpClient.GetAsync("api/v1/integrations/github/launcher/versions");
        //
        // if (response.StatusCode != HttpStatusCode.OK)
        //     Assert.Fail();
        //
        // var versions = JsonConvert.DeserializeObject<ResponseMessage<List<LauncherVersionReadDto>>>(await response.Content.ReadAsStringAsync());
        //
        // var newVersion = versions.Data[0].Version;
        //
        // var projectPath = Path.Combine(GmlManager.System.DefaultInstallation, "GmlServer", "Launcher", newVersion, $"Gml.Launcher-{newVersion.Replace("v", "")}", "src");
        //
        // var gmlClient = await TestHelper.GetFilesFolder(Path.Combine(projectPath, "Gml.Client"));
        // var notificationLib = await TestHelper.GetFilesFolder(Path.Combine(projectPath, "GamerVII.Notification.Avalonia"));
        //
        // // Скачивание Gml.Client
        // var downloadGmlClient = await TestHelper.DownloadGithubProject(projectPath, "Gml-Launcher", "Gml.Client", newVersion);
        // // Скачивание GamerVII.Notification.Avalonia
        // var downloadNotificationLib = await TestHelper.DownloadGithubProject(projectPath, "GamerVII-NET",
        //     "GamerVII.Notification.Avalonia", "master", false);
        //
        // Assert.Multiple(() =>
        // {
        //     Assert.That(downloadNotificationLib, Is.Not.Null);
        //     Assert.That(downloadGmlClient, Is.Not.Null);
        // });
    }

    [Test]
    [Order(7)]
    public async Task BuildLauncherTest()
    {
        if (_launcherHub.State != HubConnectionState.Connected)
            await _launcherHub.StartAsync();

        var response = await _httpClient.GetAsync("api/v1/integrations/github/launcher/versions");

        if (response.StatusCode != HttpStatusCode.OK)
            Assert.Fail();

        var versions = JsonConvert.DeserializeObject<ResponseMessage<List<LauncherVersionReadDto>>>(await response.Content.ReadAsStringAsync());

        var messageReceived = new TaskCompletionSource<string>();

        await _launcherHub.SendCoreAsync("Compile", [versions.Data[0].Version, new [] { "win-x64" }]);

        _launcherHub.On("LauncherBuildEnded", () =>
        {
            messageReceived.SetResult("Compile Launcher Success.");
        });

        _launcherHub.On<string>("Log", (message) =>
        {
            Debug.WriteLine(message);
        });

        var message = await messageReceived.Task;

        Assert.Multiple(() =>
        {
            Assert.That(message, Is.Not.Null);
        });
    }

    [Test]
    [Order(8)]
    public async Task UpdateLauncherTest()
    {
        var responseBuilds = await _httpClient.GetAsync("api/v1/launcher/builds");

        if (responseBuilds.StatusCode != HttpStatusCode.OK)
            Assert.Fail();

        var launcherBuilds = JsonConvert.DeserializeObject<ResponseMessage<List<LauncherBuildReadDto>>>(await responseBuilds.Content.ReadAsStringAsync());

        var launcherUpdate = new MultipartFormDataContent();
        launcherUpdate.Add(new StringContent("2.1.0.0"), "Version");
        launcherUpdate.Add(new StringContent(Name.FullName()), "Title");
        launcherUpdate.Add(new StringContent(Address.StreetAddress()), "Description");
        launcherUpdate.Add(new StringContent(launcherBuilds.Data[0].Name), "LauncherBuild");

        var response = await _httpClient.PostAsync("/api/v1/launcher/upload", launcherUpdate);

        var content = await response.Content.ReadAsStringAsync();

        Assert.Multiple(() =>
        {
            Assert.That(content, Is.Not.Null);
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        });
    }

    [Test]
    [Order(9)]
    public async Task UpdateAuthMethodTest()
    {
        var httpContent = TestHelper.CreateJsonObject(new
        {
            AuthType = 2,
            Endpoint = "http://recloud.tech/auth.php"
        });

        var response = await _httpClient.PutAsync("/api/v1/integrations/auth", httpContent);

        var content = await response.Content.ReadAsStringAsync();

        Assert.Multiple(() =>
        {
            Assert.That(content, Is.Not.Null);
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        });
    }

    [Test]
    [Order(10)]
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
    [Order(11)]
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
    [Order(12)]
    public async Task AuthForLauncherTest()
    {
        var model = JsonConvert.SerializeObject(new BaseUserPassword
        {
            Login = "test",
            Password = "test"
        });

        var data = new StringContent(model, Encoding.UTF8, "application/json");

        _httpClient.DefaultRequestHeaders.Add("X-HWID", "NOT_FOUND_NOT_SUPPORTED");
        _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd(
            $"Gml.Launcher-Client-GmlClientManager/1.0 (OS: {Environment.OSVersion};)");
        var response = await _httpClient.PostAsync("/api/v1/integrations/auth/signin", data);

        var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);

        Assert.Multiple(() =>
        {
            Assert.That(content, Is.Not.Null);
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        });
    }
}
