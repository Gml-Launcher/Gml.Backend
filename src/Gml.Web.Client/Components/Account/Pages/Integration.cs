using Gml.Web.Client.Services.Api;
using Gml.WebApi.Models.Dtos.Auth;
using Microsoft.AspNetCore.Components;

namespace Gml.Web.Client.Components.Account.Pages;

public partial class Integration
{
    [Inject] protected GmlApiService GmlApiService { get; set; } = null!;

    private List<ReadIntegrationDto> integrationDtos = new();
    internal ReadIntegrationDto? ActiveIntegration;
    internal UpdateIntegrationDto? UpdateIntegrationDto = new ();

    protected override async Task OnInitializedAsync()
    {
        try
        {
            integrationDtos = [..await GmlApiService.GetIntegrationServices()];
            ActiveIntegration = await GmlApiService.GetActiveIntegration();

            if (ActiveIntegration != null)
            {
                UpdateIntegrationDto = new UpdateIntegrationDto
                {
                    AuthType = ActiveIntegration.AuthType,
                    Endpoint = ActiveIntegration.Endpoint
                };
            }
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }

    private async Task UpdateActiveService(ReadIntegrationDto integrationDto)
    {
        UpdateIntegrationDto = new UpdateIntegrationDto
        {
            AuthType = integrationDto.AuthType
        };

        if (await GmlApiService.UpdateIntegration(UpdateIntegrationDto))
        {
            ActiveIntegration = integrationDto;
        }
    }

    private async Task SaveActiveIntegrationChanges()
    {
        if (UpdateIntegrationDto == null)
        {
            return;
        }

        if (await GmlApiService.UpdateIntegration(UpdateIntegrationDto))
        {
        }
    }
}
