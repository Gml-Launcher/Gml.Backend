using System.Text;
using Gml.Web.Client.Models.Profiles;
using Gml.WebApi.Models.Dtos.Auth;
using Gml.WebApi.Models.Dtos.Profiles;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.SignalR.Client;
using Newtonsoft.Json;
using PackProfileDto = Gml.WebApi.Models.Dtos.Profiles.PackProfileDto;
using ProfileCreateInfoDto = Gml.WebApi.Models.Dtos.Profiles.ProfileCreateInfoDto;
using RemoveProfileDto = Gml.WebApi.Models.Dtos.Profiles.RemoveProfileDto;

namespace Gml.Web.Client.Services.Api;

internal delegate void ProgressChanged(int progress);

internal delegate void Packed(bool isEnded);

internal delegate void Installed();

public class GmlApiService
{
    private readonly HubConnection _hubConnection;
    private HttpClient HttpClient { get; }
    private NavigationManager NavigationManager { get; }
    internal event ProgressChanged ProgressChangedEvent;
    internal event Packed PackedEvent;
    internal event Installed InstalledEvent;

    public GmlApiService(NavigationManager navigationManager, IHttpClientFactory httpClientFactory)
    {
        HttpClient = httpClientFactory.CreateClient("GmlApi");

        var byteArray = Encoding.ASCII.GetBytes("admin:admin");
        HttpClient.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", Convert.ToBase64String(byteArray));

        NavigationManager = navigationManager;

        _hubConnection = new HubConnectionBuilder()
            .WithUrl(NavigationManager.ToAbsoluteUri(
                $"{HttpClient.BaseAddress!.AbsoluteUri}ws/profiles/restore"))
            .Build();

        _hubConnection.On<int>("ChangeProgress", async (progress) => { ProgressChangedEvent?.Invoke(progress); });

        _hubConnection.On<string>("FileChanged", async (fileName) =>
        {
            // ProgressChangedEvent?.Invoke(50);
        });

        _hubConnection.On("SuccessInstalled", async () => { InstalledEvent?.Invoke(); });

        _hubConnection.On("SuccessPacked", async () => { PackedEvent?.Invoke(true); });


        _hubConnection.StartAsync();
    }

    public async Task<IEnumerable<ExtendedReadProfileDto>> GetProfilesAsync()
    {
        var response = await HttpClient.GetAsync("api/profiles");

        if (!response.IsSuccessStatusCode)
            return Enumerable.Empty<ExtendedReadProfileDto>();

        var content = await response.Content.ReadAsStringAsync();

        return JsonConvert.DeserializeObject<List<ExtendedReadProfileDto>>(content) ??
               Enumerable.Empty<ExtendedReadProfileDto>();
    }

    public async Task<ExtendedReadProfileDto?> CreateProfileAsync(CreateProfileDto profileDto)
    {
        var jsonContent = new StringContent(JsonConvert.SerializeObject(profileDto), Encoding.UTF8, "application/json");

        var response = await HttpClient.PostAsync("/api/profiles", jsonContent);

        if (!response.IsSuccessStatusCode)
            return null;

        var content = await response.Content.ReadAsStringAsync();

        return JsonConvert.DeserializeObject<ExtendedReadProfileDto>(content);
    }

    public Task<IEnumerable<VersionInfo>> GetAllowedVersions()
    {
        return Task.FromResult(new List<VersionInfo>
        {
            new("1.7.10", "1.7.10"),
            new("1.20.1", "1.20.1"),
            new("1.19.4", "1.19.4"),
        }.AsEnumerable());
    }

    public Task<IEnumerable<LoaderType>> GetAllowedGameLoaders()
    {
        return Task.FromResult(new List<LoaderType>
        {
            new(1, "Vanilla"),
            new(2, "Forge"),
        }.AsEnumerable());
    }

    public async Task<bool> RemoveProfile(RemoveProfileDto removeProfileDto)
    {
        var response = await HttpClient.DeleteAsync($"/api/profiles/{removeProfileDto.ClientName}");

        return !response.IsSuccessStatusCode;
    }

    public async Task<GetProfileInfo?> GetProfileInfoAsync(ProfileCreateInfoDto removeProfileDto)
    {
        var data = new StringContent(JsonConvert.SerializeObject(removeProfileDto), Encoding.UTF8, "application/json");

        var response = await HttpClient.PostAsync("api/profiles/info", data);

        var content = await response.Content.ReadAsStringAsync();

        return JsonConvert.DeserializeObject<GetProfileInfo>(content);
    }

    public async Task UpdateProfile(UpdateProfileDto updateProfileDto)
    {
        var data = new StringContent(JsonConvert.SerializeObject(updateProfileDto), Encoding.UTF8, "application/json");

        var response = await HttpClient.PutAsync("api/profiles/info", data);
    }

    public async Task PackProfile(PackProfileDto profile)
    {
        await _hubConnection.SendAsync("Pack", profile.Name);
    }


    public async Task DownloadProfile(string profileName, string osType)
    {
        await _hubConnection.SendAsync("Restore", profileName, osType);
    }

    public async Task<IEnumerable<ReadIntegrationDto>> GetIntegrationServices()
    {
        var response = await HttpClient.GetAsync("api/auth");

        if (!response.IsSuccessStatusCode)
            return Enumerable.Empty<ReadIntegrationDto>();

        var content = await response.Content.ReadAsStringAsync();

        return JsonConvert.DeserializeObject<List<ReadIntegrationDto>>(content) ??
               Enumerable.Empty<ReadIntegrationDto>();
    }

    public async Task<ReadIntegrationDto?> GetActiveIntegration()
    {
        var response = await HttpClient.GetAsync("/api/auth/active");

        if (!response.IsSuccessStatusCode)
            return null;

        var content = await response.Content.ReadAsStringAsync();

        return JsonConvert.DeserializeObject<ReadIntegrationDto>(content);
    }

    public async Task<bool> UpdateIntegration(UpdateIntegrationDto updateIntegrationDto)
    {
        var data = new StringContent(JsonConvert.SerializeObject(updateIntegrationDto), Encoding.UTF8, "application/json");

        var response = await HttpClient.PutAsync("api/auth/active", data);

        return response.IsSuccessStatusCode;
    }
}
