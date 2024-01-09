using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Gml.AdminPanel.Services;
using Microsoft.JSInterop;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using Radzen;
using Radzen.Blazor;

namespace Gml.AdminPanel.Components.Pages
{
    public partial class ProfileAdd
    {
        [Inject]
        protected IJSRuntime JSRuntime { get; set; }

        [Inject]
        protected NavigationManager NavigationManager { get; set; }

        [Inject]
        protected DialogService DialogService { get; set; }

        [Inject]
        protected TooltipService TooltipService { get; set; }

        [Inject]
        protected ContextMenuService ContextMenuService { get; set; }

        [Inject]
        protected NotificationService NotificationService { get; set; }

        [Inject]
        protected GmlApiService GmlApiService { get; set; }

        protected override async Task OnInitializedAsync()
        {
            MinecraftVersions = await GmlApiService.OnGetMinecraftVersions();
            GameLoaders = await GmlApiService.OnGetLoaderVersions();
            GameProfiles = await GmlApiService.GetProfiles();
        }

        protected IEnumerable<string> MinecraftVersions;
        protected IEnumerable<GmlApiService.GameLoader> GameLoaders;
        protected GmlApiService.GameLoader SelectedGameLoader;
        protected string ProfileName;
        protected string SelectedMinecraftVersion;

        protected IEnumerable<Gml.AdminPanel.Models.GmlApi.GetProfileDto> GameProfiles;

        protected async Task OnCreateProfile()
        {

            if (string.IsNullOrEmpty(ProfileName))
            {
                NotificationService.Notify(new NotificationMessage
                {
                    Detail = "The \"Name\" field is required"
                });
                return;
            }

            if (GameProfiles.Any(c => c.Name == ProfileName))
            {
                NotificationService.Notify(new NotificationMessage
                {
                    Detail = "The profile name already exists"
                });
                return;

            }

            if (SelectedGameLoader == null)
            {
                NotificationService.Notify(new NotificationMessage
                {
                    Detail = "The \"Game loader\" field is required"
                });
                return;
            }

            if (string.IsNullOrEmpty(SelectedMinecraftVersion))
            {
                NotificationService.Notify(new NotificationMessage
                {
                    Detail = "The \"Minecraft version\" field is required"
                });
                return;
            }

            await GmlApiService.CreateProfile(new GmlApiService.CreateProfileDto()
            {
                Name = ProfileName,
                Version = SelectedMinecraftVersion,
                GameLoader = SelectedGameLoader.Value

            });


            GameProfiles = await GmlApiService.GetProfiles();
        }
    }
}
