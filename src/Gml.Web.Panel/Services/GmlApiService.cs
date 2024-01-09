using System.Net.Http.Headers;
using System.Text;
using Gml.AdminPanel.Models.GmlApi;
using Microsoft.AspNetCore.Components;
using Newtonsoft.Json;
using File = Gml.AdminPanel.Models.GmlApi.File;

namespace Gml.AdminPanel.Services
{
    public partial class GmlApiService
    {
        private readonly HttpClient httpClient;
        private readonly NavigationManager navigationManager;

        public GmlApiService(NavigationManager navigationManager, IHttpClientFactory httpClientFactory)
        {
            this.httpClient = httpClientFactory.CreateClient("GmlApi");
            this.navigationManager = navigationManager;
        }

        private async Task AuthorizeRequest(HttpRequestMessage request)
        {
            var bytes = Encoding.ASCII.GetBytes("Admin:Admin");
            request.Headers.Authorization = new AuthenticationHeaderValue("Basic", Convert.ToBase64String(bytes));
        }

        partial void OnGetProfiles(HttpRequestMessage request);
        partial void OnGetProfilesResponse(HttpResponseMessage response);

        public async Task<IEnumerable<Gml.AdminPanel.Models.GmlApi.GetProfileDto>> GetProfiles()
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles");

            var request = new HttpRequestMessage(HttpMethod.Get, uri);

            OnGetProfiles(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnGetProfilesResponse(response);

            return await response.Content.ReadFromJsonAsync<IEnumerable<Gml.AdminPanel.Models.GmlApi.GetProfileDto>>();
        }

        partial void OnCreateProfile(HttpRequestMessage request);
        partial void OnCreateProfileResponse(HttpResponseMessage response);

        public async Task CreateProfile(CreateProfileDto profileDto)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles");

            var request = new HttpRequestMessage(HttpMethod.Post, uri);
            request.Content = new StringContent(JsonConvert.SerializeObject(profileDto), Encoding.UTF8, "application/json");

            OnCreateProfile(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnCreateProfileResponse(response);
        }

        partial void OnGetProfileInfo(HttpRequestMessage request);
        partial void OnGetProfileInfoResponse(HttpResponseMessage response);

        public async Task<Gml.AdminPanel.Models.GmlApi.GetProfileInfo> LoadProfileInfo(ProfileCreateInfoDto project)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles/restore");

            var request = new HttpRequestMessage(HttpMethod.Post, uri);
            request.Content = new StringContent(JsonConvert.SerializeObject(project), Encoding.UTF8, "application/json");

            OnGetProfileInfo(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnGetProfileInfoResponse(response);

            var content = await response.Content.ReadAsStringAsync();

            return JsonConvert.DeserializeObject<GetProfileInfo>(content);
        }

        public async Task<Gml.AdminPanel.Models.GmlApi.GetProfileInfo> GetProfileInfo(ProfileCreateInfoDto project)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles/info");

            var request = new HttpRequestMessage(HttpMethod.Post, uri);
            request.Content = new StringContent(JsonConvert.SerializeObject(project), Encoding.UTF8, "application/json");

            OnGetProfileInfo(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnGetProfileInfoResponse(response);

            var content = await response.Content.ReadAsStringAsync();

            return JsonConvert.DeserializeObject<GetProfileInfo>(content);
        }

        partial void OnPackProfile(HttpRequestMessage request);
        partial void OnPackProfileResponse(HttpResponseMessage response);

        public async Task PackProfile(PackProfileDto packProfileDto)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles/pack");

            var request = new HttpRequestMessage(HttpMethod.Post, uri);

            request.Content = new StringContent(JsonConvert.SerializeObject(packProfileDto), Encoding.UTF8, "application/json");

            OnPackProfile(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnPackProfileResponse(response);
        }

        partial void OnDownloadFile(HttpRequestMessage request);
        partial void OnDownloadFileResponse(HttpResponseMessage response);

        public async Task DownloadFile(string fileHash)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/file/{fileHash}");

            var request = new HttpRequestMessage(HttpMethod.Get, uri);

            OnDownloadFile(request);

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            OnDownloadFileResponse(response);
        }

        public async Task RemoveProfile(RemoveProfileDto removeProfileDto)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/profiles");

            var request = new HttpRequestMessage(HttpMethod.Delete, uri);

            request.Content = new StringContent(JsonConvert.SerializeObject(removeProfileDto), Encoding.UTF8, "application/json");

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();
        }



        public async Task<IEnumerable<File>> AddWhiteList(FileWhiteListDto fileWhiteListDto)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/file/whitelist");

            var request = new HttpRequestMessage(HttpMethod.Post, uri);
            request.Content = new StringContent(JsonConvert.SerializeObject(fileWhiteListDto), Encoding.UTF8, "application/json");

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            return JsonConvert.DeserializeObject<List<File>>(content);
        }

        public async Task<IEnumerable<File>> RemoveWhiteList(FileWhiteListDto fileWhiteListDto)
        {
            var uri = new Uri(httpClient.BaseAddress, $"api/file/whitelist");

            var request = new HttpRequestMessage(HttpMethod.Delete, uri);
            request.Content = new StringContent(JsonConvert.SerializeObject(fileWhiteListDto), Encoding.UTF8, "application/json");

            await AuthorizeRequest(request);

            var response = await httpClient.SendAsync(request);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            return JsonConvert.DeserializeObject<List<File>>(content);
        }


        public async Task<IEnumerable<string>> OnGetMinecraftVersions()
        {
            return new List<string>
            {
                "1.7.10",
                "1.20.1",
            };;
        }

        public async Task<IEnumerable<GameLoader>> OnGetLoaderVersions()
        {
            return new List<GameLoader>
            {
                new GameLoader("Vanilla", 1),
                new GameLoader("Forge", 2),
            };
        }

        public class GameLoader(string name, int value)
        {
            public string Name { get; set; } = name;
            public int Value { get; set; } = value;

            public override string ToString()
            {
                return Name;
            }
        }

        public class CreateProfileDto
        {
            public string Name { get; set; }
            public string Version { get; set; }
            public int GameLoader { get; set; }
        }
    }
}
