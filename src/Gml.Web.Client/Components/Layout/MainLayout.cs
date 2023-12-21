using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using Radzen;

namespace Gml.Web.Client.Components.Layout;

public partial class MainLayout
{
    [Inject]
    protected IJSRuntime JSRuntime { get; set; } = null!;

    [Inject]
    protected NavigationManager NavigationManager { get; set; } = null!;

    // [Inject]
    // protected DialogService DialogService { get; set; } = null!;
    //
    // [Inject]
    // protected TooltipService TooltipService { get; set; } = null!;
    //
    // [Inject]
    // protected ContextMenuService ContextMenuService { get; set; } = null!;
    //
    // [Inject]
    // protected NotificationService NotificationService { get; set; } = null!;

    private bool sidebarExpanded = true;
    // [Inject]
    // protected IAuthenticationUserState AuthenticationUserState { get; set; } = null!;

    private void SidebarToggleClick()
    {
        sidebarExpanded = !sidebarExpanded;
    }

    // protected void ProfileMenuClick(RadzenProfileMenuItem args)
    // {
    //     // if (args.Value == "Logout") NavigationManager.NavigateTo($"{Endpoints.Authentication}/logout", true);
    // }
}
