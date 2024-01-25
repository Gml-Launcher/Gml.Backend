using Gml.Web.Client.Models.Profiles;
using Gml.Web.Client.Services.Api;
using Gml.WebApi.Models.Dtos.Profiles;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Mvc;

namespace Gml.Web.Client.Components.Account.Pages;

public partial class Profiles
{
    protected CreateProfileDto CreateProfileDto { get; set; } = new();
    protected List<ExtendedReadProfileDto> ProfileDtos = new();
    protected List<VersionInfo> GameVersions = new();
    protected List<LoaderType> GameLoaders = new();
    protected bool IsTableProcessing;

    protected bool IsSelectedAllProfiles
    {
        get => _isSelectedAllProfiles;
        set
        {
            _isSelectedAllProfiles = value;
            SelectToggle(value);
        }
    }

    private bool _isSelectedAllProfiles;
    [Inject] protected GmlApiService GmlApiService { get; set; }

    protected override async Task OnInitializedAsync()
    {
        try
        {
            ProfileDtos = [..await GmlApiService.GetProfilesAsync()];
            GameVersions = [..await GmlApiService.GetAllowedVersions()];
            GameLoaders = [..await GmlApiService.GetAllowedGameLoaders()];
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }

    private async Task CreateProfileCommand()
    {
        if (string.IsNullOrEmpty(CreateProfileDto.Name))
        {
            return;
        }

        if (ProfileDtos.Any(c => c.Name == CreateProfileDto.Name))
        {
            return;
        }

        IsTableProcessing = true;
        var newProfile = await GmlApiService.CreateProfileAsync(CreateProfileDto);

        if (newProfile != null)
        {
            ProfileDtos.Add(newProfile);
            CreateProfileDto = new CreateProfileDto();
        }
        IsTableProcessing = false;
    }

    private async Task RemoveProfileCommand(ExtendedReadProfileDto profile)
    {
        IsTableProcessing = true;

        var isSuccess = await GmlApiService.RemoveProfile(new RemoveProfileDto
        {
            ClientName = profile.Name,
            RemoveFiles = true
        });

        ProfileDtos.Remove(profile);
        IsTableProcessing = false;
    }

    private async Task RemoveSelectedCollection()
    {
        IsTableProcessing = true;

        foreach (var profile in ProfileDtos.Where(c => c.IsSelected))
        {
            GmlApiService.RemoveProfile(new RemoveProfileDto
            {
                ClientName = profile.Name,
                RemoveFiles = true
            });
        }

        await OnInitializedAsync();

        IsTableProcessing = false;
    }

    private async Task UploadImage(InputFileChangeEventArgs e)
    {
        var imageFile = e.File;
        var buffer = new byte[imageFile.Size];
        await using var stream = imageFile.OpenReadStream();
        var readAsync = await stream.ReadAsync(buffer);
        CreateProfileDto.IconBase64 = Convert.ToBase64String(buffer);
    }

    private void SelectToggle(bool isSelected)
    {
        ProfileDtos.ForEach(c => c.IsSelected = isSelected);
    }
}
