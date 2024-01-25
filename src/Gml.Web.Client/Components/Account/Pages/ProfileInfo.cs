using Gml.Web.Client.Models.Profiles;
using Gml.Web.Client.Services.Api;
using Gml.WebApi.Models.Dtos.Profiles;
using Gml.WebApi.Models.Enums.System;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using PackProfileDto = Gml.WebApi.Models.Dtos.Profiles.PackProfileDto;
using ProfileCreateInfoDto = Gml.WebApi.Models.Dtos.Profiles.ProfileCreateInfoDto;

namespace Gml.Web.Client.Components.Account.Pages;

public partial class ProfileInfo
{
    protected UpdateProfileDto UpdateProfileDto { get; set; } = new();
    protected int ProgressPercentage { get; set; }
    protected bool IsProcessing { get; set; } = true;
    [Inject] protected GmlApiService GmlApiService { get; set; }
    [Inject] protected NavigationManager NavigationManager { get; set; }
    [Parameter] public string ProfileName { get; set; }

    private GetProfileInfo? Profile { get; set; }

    protected override async Task OnInitializedAsync()
    {
        Task.Run(async () =>
        {
            Profile = await GmlApiService.GetProfileInfoAsync(new ProfileCreateInfoDto
            {
                ClientName = ProfileName
            });

            if (Profile != null)
            {
                UpdateProfileDto.Name = Profile.ProfileName;
                UpdateProfileDto.IconBase64 = Profile.IconBase64;
                UpdateProfileDto.Description = Profile.Description;

                await InvokeAsync(StateHasChanged);
            }

            GmlApiService.ProgressChangedEvent += async progress =>
            {
                IsProcessing = true;

                if (ProgressPercentage != progress)
                {
                    ProgressPercentage = progress;

                    await InvokeAsync(StateHasChanged);
                }
            };

            GmlApiService.PackedEvent += async isPacked =>
            {
                IsProcessing = false;
                await InvokeAsync(StateHasChanged);
            };

            GmlApiService.InstalledEvent += async () =>
            {
                IsProcessing = false;
                await InvokeAsync(StateHasChanged);
            };

            await Task.Delay(TimeSpan.FromSeconds(3));

            IsProcessing = false;

            await InvokeAsync(StateHasChanged);
        });
    }


    private async Task OpenFileManager()
    {
        var uri = new Uri(NavigationManager.Uri);

        NavigationManager.NavigateTo($"http://{uri.Host}:5005");
    }

    private async Task SaveChangesCommand()
    {
        UpdateProfileDto.OriginalName = ProfileName;
        await GmlApiService.UpdateProfile(UpdateProfileDto);

        ProfileName = UpdateProfileDto.Name;
        Profile.ProfileName = UpdateProfileDto.Name;
        Profile.IconBase64 = UpdateProfileDto.IconBase64;
        NavigationManager.NavigateTo($"Profiles/{ProfileName}", false);
    }

    private async Task PackProfileCommand()
    {
        if (Profile != null)
        {
            ProgressPercentage = 0;
            IsProcessing = true;
            await GmlApiService.PackProfile(new PackProfileDto(Profile.ProfileName));
        }
    }

    private async Task UploadImage(InputFileChangeEventArgs e)
    {
        try
        {
            IsProcessing = true;
            var imageFile = e.File;
            var buffer = new byte[imageFile.Size];
            await using var stream = imageFile.OpenReadStream();
            var readAsync = await stream.ReadAsync(buffer);
            UpdateProfileDto.IconBase64 = Convert.ToBase64String(buffer);
        }
        catch (Exception exception)
        {
            Console.WriteLine(exception);
        }
        finally
        {
            IsProcessing = false;
        }
    }


    private Task DownloadWindowsCommand()
    {
        return LoadAdditionalData(OsType.Windows);
    }

    private Task DownloadLinuxCommand()
    {
        return LoadAdditionalData(OsType.Linux);
    }

    private Task DownloadOsxCommand()
    {
        return LoadAdditionalData(OsType.OsX);
    }

    private async Task LoadAdditionalData(OsType osType)
    {
        // var isSuccess = await DialogService.Confirm(
        //     $"It may take a long time to download the client, as well as overwrite the current settings, do you want to continue?",
        //     "Confirmation",
        //     new ConfirmOptions() { OkButtonText = "Yes", CancelButtonText = "No" });
        //
        // if (isSuccess is not true)
        //     return;

        IsProcessing = true;
        ProgressPercentage = 0;

        await GmlApiService.DownloadProfile(ProfileName, osType.ToString());

        return;
    }
}
