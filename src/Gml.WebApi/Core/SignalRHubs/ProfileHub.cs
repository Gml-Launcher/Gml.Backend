using System.ComponentModel;
using Gml.Core.Launcher;
using Gml.Core.User;
using Gml.WebApi.Models.Enums.System;
using GmlCore.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace Gml.WebApi.Core.SignalRHubs;

public class ProfileHub : Hub
{
    private readonly IGmlManager _gmlManager;

    public ProfileHub(IGmlManager gmlManager)
    {
        _gmlManager = gmlManager;
    }

    public async Task Restore(string clientName, string osTypeValue)
    {
        var profile = await _gmlManager.Profiles.GetProfile(clientName);

        if (profile == null)
            return;

        if (!Enum.TryParse(osTypeValue, out OsType osType))
            return;

        profile.GameLoader.ProgressChanged += SendProgress;
        profile.GameLoader.FileChanged += SendFileChanged;

        var profileInfoRead = await _gmlManager.Profiles.RestoreProfileInfo(profile.Name, new StartupOptions
        {
            FullScreen = false,
            ScreenHeight = 500,
            ScreenWidth = 500,
            ServerIp = string.Empty,
            ServerPort = 25565,
            MaximumRamMb = 10,
            OsType = osType
        }, new User
        {
            Name = "Test",
            AccessToken = "Test",
            Uuid = "Test"
        });

        profile.GameLoader.ProgressChanged -= SendProgress;
        profile.GameLoader.FileChanged -= SendFileChanged;

        await Clients.All.SendAsync("ChangeProgress", 100);
        await Clients.All.SendAsync("SuccessInstalled");
    }

    private async void SendFileChanged(string file)
    {
        if (!string.IsNullOrEmpty(file))
            await Clients.All.SendAsync("FileChanged", file);
    }

    private async void SendProgress(object sender, ProgressChangedEventArgs e)
    {
        await Clients.All.SendAsync("ChangeProgress", e?.ProgressPercentage);
    }
}
