using CmlLib.Core;
using CmlLib.Core.Auth;
using CmlLib.Core.Installer.Forge;
using Gml.Core.Launcher;
using Gml.WebApi.Core.Handlers;
using Gml.WebApi.Models.Dtos.Profiles;
using Gml.WebApi.Models.Enums.System;
using GmlCore.Interfaces;

namespace Gml.WebApi.Tests;

public class Tests
{
    private RequestHandler _requestHandler;
    private IGmlManager _gmlManager;

    [SetUp]
    public void Setup()
    {
        _requestHandler = new RequestHandler();
        _gmlManager = new GmlManager(new GmlSettings("GamerVIINet"));
    }

    [Test]
    public async Task GetProfileInfo()
    {
        // await RequestHandler.GetProfileInfo(_gmlManager, new ProfileCreateInfoDto
        // {
        //     ClientName = "AztexCraft",
        //     GameAddress = "192.168.0.1",
        //     GamePort = 25565,
        //     RamSize = 4096,
        //     SizeX = 1500,
        //     SizeY = 900,
        //     IsFullScreen = false,
        //     UserAccessToken = "sergsecgrfsecgriseuhcygrshecngrysicugrbn7csewgrfcsercgser",
        //     UserName = "GamerVII",
        //     OsType = (int)OsType.Windows,
        //     UserUuid = "31f5f477-53db-4afd-b88d-2e01815f4887"
        // });
    }

    [Test, Order(1)]
    public async Task DownloadForge()
    {
        var launcher = new CMLauncher(new MinecraftPath());

        var forge = new MForge(launcher);

        var forgeVersion = await forge.Install("1.20.1", true);

        var process = launcher.CreateProcess(forgeVersion, new MLaunchOption
        {
            MaximumRamMb = 2048,
            Session = MSession.GetOfflineSession("hello123"),
        });

        process.Start();
    }
}
