using System.Text;
using Gml.Web.Api.Domains.System;
using Gml.Web.Api.Dto.Messages;
using Gml.Web.Api.Dto.Profile;
using Microsoft.AspNetCore.Mvc.Testing;
using Newtonsoft.Json;

namespace Gml.Api.Tests;

public class UnitTest1
{
    [Fact]
    public async Task GetProfiles()
    {
        // var webApplicationFactory = new WebApplicationFactory<Program>();
        //
        // var httpClient = webApplicationFactory.CreateClient();
        //
        // var response = await httpClient.GetAsync("/api/v1/profiles");
        //
        // var content = await response.Content.ReadAsStringAsync();
        //
        // var model = JsonConvert.DeserializeObject<ResponseMessage<List<ProfileReadDto>>>(content);
        //
        // response.EnsureSuccessStatusCode();
    }


    [Fact]
    public async Task CreateProfile()
    {
        // var webApplicationFactory = new WebApplicationFactory<Program>();
        //
        // var httpClient = webApplicationFactory.CreateClient();
        //
        // var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/profiles");
        // request.Headers.Add("Authorization", $"Bearer {Environment.GetEnvironmentVariable("USER_ACCESS_TOKEN")}");
        // var data = new MultipartFormDataContent();
        // // content.Add(new StreamContent(File.OpenRead("/C:/Users/aa.terentiev/Downloads/1052.png")), "icon", "/C:/Users/aa.terentiev/Downloads/1052.png");
        // data.Add(new StringContent("OntaCraft"), "Name");
        // data.Add(new StringContent("OntaCraft Description"), "Description");
        // data.Add(new StringContent("1.19.4"), "Version");
        // data.Add(new StringContent("2"), "GameLoader");
        // request.Content = data;
        //
        // var response = await httpClient.SendAsync(request);
        //
        // var content = await response.Content.ReadAsStringAsync();
        //
        // response.EnsureSuccessStatusCode();
    }


    [Fact]
    public async Task GetProfileInfo()
    {
        // var webApplicationFactory = new WebApplicationFactory<Program>();
        //
        // var httpClient = webApplicationFactory.CreateClient();
        //
        // var profile = new ProfileCreateInfoDto
        // {
        //     ProfileName = "OntaCraft",
        //     GameAddress = "192.168.1.1",
        //     GamePort = 25565,
        //     RamSize = 4096,
        //     WindowWidth = 900,
        //     WindowHeight = 600,
        //     IsFullScreen = true,
        //     OsType = ((int)OsType.Windows).ToString(),
        //     OsArchitecture = Environment.Is64BitOperatingSystem ? "64" : "32",
        //     UserAccessToken = "sergsecgrfsecgriseuhcygrshecngrysicugrbn7csewgrfcsercgser",
        //     UserName = "GamerVII",
        //     UserUuid = "userUuid"
        // };
        //
        // var data = JsonConvert.SerializeObject(profile);
        //
        // var response = await httpClient.PostAsync("/", new StringContent(data, Encoding.UTF8, "application/json"));
        //
        // response.EnsureSuccessStatusCode();
        //
        // var content = await response.Content.ReadAsStringAsync();
        //
        // var model = JsonConvert.DeserializeObject<ResponseMessage<ProfileReadInfoDto>>(content);
    }
}
