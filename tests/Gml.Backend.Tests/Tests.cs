using System.Diagnostics;
using System.Net;
using Faker;
using Gml.Web.Api.Dto.Messages;
using Gml.Web.Api.Dto.Profile;
using GmlCore.Interfaces.Enums;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.SignalR.Client;
using Newtonsoft.Json;

namespace Gml.Backend.Tests;

public class Tests
{
    private HubConnection _profileHub;
    private HubConnection _launcherHub;
    private HttpClient _httpClient;
    private WebApplicationFactory<Program> _webApplicationFactory;
    private readonly string _profileName = "UnitTestProfile";

    [SetUp]
    public async Task Setup()
    {
        Environment.SetEnvironmentVariable("SECURITY_KEY", "jkuhbsfgvuk4gfikhn8i7wa34rkbqw23");
        Environment.SetEnvironmentVariable("PROJECT_NAME", "GmlServer");
        Environment.SetEnvironmentVariable("PROJECT_DESCRIPTION", "GmlServer Description");
        Environment.SetEnvironmentVariable("PROJECT_POLICYNAME", "GmlPolicy");
        Environment.SetEnvironmentVariable("PROJECT_PATH", "");
        Environment.SetEnvironmentVariable("SERVICE_TEXTURE_ENDPOINT", "http://gml-web-skins:8085");

        _webApplicationFactory = new GmlApiApplicationFactory();
        _httpClient = _webApplicationFactory.CreateClient();
        _profileHub = new HubConnectionBuilder()
            .WithUrl("ws://localhost/ws/profiles/restore")
            .Build();

    }

    [TearDown]
    public void TearDown()
    {
        _httpClient.Dispose();
        _webApplicationFactory.Dispose();
        _profileHub.DisposeAsync();
        _launcherHub.DisposeAsync();
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
        await _profileHub.StartAsync();

        var messageReceived = new TaskCompletionSource<string>();

        _profileHub.On<string, string>("Log", (message, profileName) =>
        {
            if (profileName == _profileName)
                Debug.WriteLine(message);
        });

        _profileHub.On("SuccessInstalled", () =>
        {
            messageReceived.SetResult(_profileName);
        });

        var message = await messageReceived.Task;

        Assert.Multiple(() =>
        {
            Assert.That(message, Is.Not.Null);
        });
    }

    [Test]
    [Order(4)]
    public async Task CompileProfileTest()
    {
        var compileDto = TestHelper.CreateJsonObject(new ProfileRestoreDto
        {
            Name = _profileName
        });

        var response = await _httpClient.PostAsync("/api/v1/profiles/compile", compileDto);

        var content = await response.Content.ReadAsStringAsync();

        var model = JsonConvert.DeserializeObject<ResponseMessage>(content);

        Assert.Multiple(() =>
        {
            Assert.That(model, Is.Not.Null);
            Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.OK));
        });
    }
}
