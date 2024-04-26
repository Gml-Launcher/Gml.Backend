using GmlCore.Interfaces;

namespace Gml.WebApi.Tests;

public class Tests
{
    // private WebApplicationFactory<Program> _webApplicationFactory;
    private IGmlManager _gmlManager;

    [SetUp]
    public void Setup()
    {
        // _webApplicationFactory = new WebApplicationFactory<Program>();
    }



    [Test, Order(1)]
    public async Task CreateProfile()
    {

    }

    [Test, Order(2)]
    public async Task GetProfileInfo()
    {
        // var httpClient = _webApplicationFactory.CreateClient();
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
        // var data = JsonSerializer.Serialize(profile);
        //
        // var response = await httpClient.PostAsync("/", new StringContent(data, Encoding.UTF8, MediaTypeHeaderValue.Parse("application/json")));
        //
        // response.EnsureSuccessStatusCode();
        //
        // var content = await response.Content.ReadAsStringAsync();
        //
        // var model = JsonSerializer.Deserialize<ResponseMessage<ProfileReadInfoDto>>(content);
        //
        // Assert.IsNotNull(model);
    }

    [Test, Order(3)]
    public async Task DownloadForge()
    {
        // var launcher = new CMLauncher(new MinecraftPath());
        //
        // var forge = new MForge(launcher);
        //
        // var forgeVersion = await forge.Install("1.19.4", true);
        //
        // var process = launcher.CreateProcess(forgeVersion, new MLaunchOption
        // {
        //     MaximumRamMb = 2048,
        //     Session = MSession.GetOfflineSession("hello123"),
        // });
        //
        // process.Start();
    }

}
