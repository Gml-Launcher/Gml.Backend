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

    private int lastProgressSended = -1;
    private int lastPackProgressSended = -1;

    public ProfileHub(IGmlManager gmlManager)
    {
        _gmlManager = gmlManager;
    }

    public async Task Pack(string clientName)
    {
        if (string.IsNullOrEmpty(clientName))
            return;

        var profile = await _gmlManager.Profiles.GetProfile(clientName);

        if (profile is null)
            return;

        await Clients.All.SendAsync("FileChanged", "Packaging...");

        _gmlManager.Profiles.PackChanged += ChangePackProgress;
        await _gmlManager.Profiles.PackProfile(profile);
        _gmlManager.Profiles.PackChanged -= ChangePackProgress;

        await Clients.All.SendAsync("SuccessPacked");
        lastPackProgressSended = -1;
    }

    private async void ChangePackProgress(ProgressChangedEventArgs e)
    {
        try
        {
            if (lastPackProgressSended == e.ProgressPercentage) return;

            lastProgressSended = e.ProgressPercentage;

            await Clients.All.SendAsync("ChangeProgress", e?.ProgressPercentage);
        }
        catch (Exception exception)
        {
            Console.WriteLine(exception);
        }
    }

    public async Task Restore(string clientName, string osTypeValue)
    {
        var profile = await _gmlManager.Profiles.GetProfile(clientName);

        if (profile == null)
            return;

        if (!Enum.TryParse(osTypeValue, out OsType osType))
            return;

        await Clients.All.SendAsync("ChangeProgress", 0);

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

        try
        {
            await Clients.All.SendAsync("ChangeProgress", 100);
            await Clients.All.SendAsync("SuccessInstalled");

            lastProgressSended = -1;
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }

    private async void SendFileChanged(string file)
    {
        try
        {
            if (!string.IsNullOrEmpty(file))
                await Clients.All.SendAsync("FileChanged", file);
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }

    private async void SendProgress(object sender, ProgressChangedEventArgs e)
    {
        try
        {
            if (lastProgressSended == e.ProgressPercentage) return;

            lastProgressSended = e.ProgressPercentage;
            await Clients.All.SendAsync("ChangeProgress", e?.ProgressPercentage);
        }
        catch (Exception exception)
        {
            Console.WriteLine(exception);
        }
    }
}
