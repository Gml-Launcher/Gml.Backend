using Gml.Core.Launcher;
using Gml.Core.User;
using Gml.WebApi.Models.Dtos.Profiles;
using Gml.WebApi.Models.Enums.System;
using GmlCore.Interfaces;
using GmlCore.Interfaces.Enums;
using Microsoft.AspNetCore.Mvc;

namespace Gml.WebApi.Core.Handlers;

public class RequestHandler
{
    public static async Task<IResult> GetClients(IGmlManager gmlManager)
    {
        var profiles = await gmlManager.Profiles.GetProfiles();

        var dto = profiles.Select(c => new ReadProfileDto
        {
            Name = c.Name,
            GameVersion = c.GameVersion,
            LaunchVersion = c.LaunchVersion,
        });

        return Results.Ok(dto);
    }

    public static async Task<IResult> LoadFile(IGmlManager gmlManager, IEnumerable<IFormFile> request)
    {
        return Results.Ok();

    }

    public static async Task<IResult> DownloadFile(IGmlManager gmlManager, string fileHash)
    {
        var file = await gmlManager.Files.GetFileInfo(fileHash);

        if (file == null)
            return Results.NotFound();

        return Results.File(string.Join(string.Empty, gmlManager.LauncherInfo.InstallationDirectory, file.Directory));
    }

    public static async Task<IResult> GetProfileWhiteList(IGmlManager gmlManager, string profileName)
    {

        var profile = await gmlManager.Profiles.GetProfile(profileName);

        return profile == null
            ? Results.BadRequest($"Profile not found by name: {profileName}")
            : Results.Ok(profile.FileWhiteList ??= []);
    }

    public static async Task<IResult> AddFileToWhiteList(IGmlManager gmlManager, [FromBody] FileWhiteListDto fileDto)
    {
        var profile = await gmlManager.Profiles.GetProfile(fileDto.ClientName);

        if (profile == null)
            return Results.NotFound($"Profile not found by name: {fileDto.ClientName}");

        var file = await gmlManager.Files.GetFileInfo(fileDto.FileHash);

        if (file == null)
            return Results.NotFound($"File not found by hash: {fileDto.FileHash}");

        await gmlManager.Profiles.AddFileToWhiteList(profile, file);

        return Results.Ok(profile.FileWhiteList);
    }

    public static async Task<IResult> RemoveFileFromWhiteList(IGmlManager gmlManager, [FromBody] FileWhiteListDto fileDto)
    {
        var profile = await gmlManager.Profiles.GetProfile(fileDto.ClientName);

        if (profile == null)
            return Results.NotFound($"Profile not found by name: {fileDto.ClientName}");

        var file = await gmlManager.Files.GetFileInfo(fileDto.FileHash);

        if (file == null)
            return Results.NotFound($"File not found by hash: {fileDto.FileHash}");

        await gmlManager.Profiles.RemoveFileFromWhiteList(profile, file);

        return Results.Ok(profile.FileWhiteList);
    }

    public static async Task<IResult> PackProfile(IGmlManager gmlManager, PackProfileDto packProfileDto)
    {
        if (string.IsNullOrEmpty(packProfileDto.ClientName))
            return Results.BadRequest();

        var profile = await gmlManager.Profiles.GetProfile(packProfileDto.ClientName);

        if (profile is null)
            return Results.NotFound();

        await gmlManager.Profiles.PackProfile(profile);

        return Results.Ok();
    }

    public static async Task<IResult> DeleteProfile(IGmlManager gmlManager, [FromBody] RemoveProfileDto removeProfile)
    {
        if (string.IsNullOrEmpty(removeProfile.ClientName))
            return Results.BadRequest();

        var profile = await gmlManager.Profiles.GetProfile(removeProfile.ClientName);

        if (profile is null)
            return Results.NotFound();

        await gmlManager.Profiles.RemoveProfile(profile, removeProfile.RemoveFiles);

        return Results.Ok();
    }

    public static async Task<IResult> RestoreProfileInfo(IGmlManager gmlManager, ProfileCreateInfoDto profile)
    {
        if (string.IsNullOrEmpty(profile.ClientName))
            return Results.BadRequest();

        var checkProfile = await gmlManager.Profiles.GetProfile(profile.ClientName);

        if (checkProfile is null)
            return Results.NotFound();

        if (!Enum.TryParse(profile.OsType.ToString(), out OsType osType))
            return Results.BadRequest();

        var profileInfoRead = await gmlManager.Profiles.RestoreProfileInfo(profile.ClientName, new StartupOptions
        {
            FullScreen = profile.IsFullScreen,
            ScreenHeight = profile.SizeY,
            ScreenWidth = profile.SizeX,
            ServerIp = profile.GameAddress,
            ServerPort = profile.GamePort,
            MaximumRamMb = profile.RamSize,
            OsType = osType
        }, new User
        {
            Name = profile.UserName,
            AccessToken = profile.UserAccessToken,
            Uuid = profile.UserUuid
        });

        return Results.Ok(profileInfoRead);
    }

    public static async Task<IResult> GetProfileInfo(IGmlManager gmlManager, ProfileCreateInfoDto profile)
    {
        if (string.IsNullOrEmpty(profile.ClientName))
            return Results.BadRequest();

        var checkProfile = await gmlManager.Profiles.GetProfile(profile.ClientName);

        if (checkProfile is null)
            return Results.NotFound();

        if (!Enum.TryParse(profile.OsType.ToString(), out OsType osType))
            return Results.BadRequest();

        var profileInfoRead = await gmlManager.Profiles.GetProfileInfo(profile.ClientName, new StartupOptions
        {
            FullScreen = profile.IsFullScreen,
            ScreenHeight = profile.SizeY,
            ScreenWidth = profile.SizeX,
            ServerIp = profile.GameAddress,
            ServerPort = profile.GamePort,
            MaximumRamMb = profile.RamSize,
            OsType = osType
        }, new User
        {
            Name = profile.UserName,
            AccessToken = profile.UserAccessToken,
            Uuid = profile.UserUuid
        });

        return Results.Ok(profileInfoRead);
    }

    public static async Task<IResult> CreateProfile(IGmlManager gmlManager, CreateProfileDto profile)
    {
        var canAddProfile = await gmlManager.Profiles.CanAddProfile(profile.Name, profile.Version);

        if (!canAddProfile)
            return Results.Conflict();

        if (!Enum.TryParse(profile.GameLoader.ToString(), out GameLoader gameLoader))
            return Results.BadRequest();

        var newProfile = await gmlManager.Profiles.AddProfile(profile.Name, profile.Version, gameLoader);

        if (newProfile == null)
            return Results.BadRequest();

        return Results.Created($"/api/profiles/{profile.Name}", new ReadProfileDto
        {
            Name = newProfile.Name,
            GameVersion = newProfile.GameVersion,
            LaunchVersion = newProfile.LaunchVersion,
        });
    }

}
