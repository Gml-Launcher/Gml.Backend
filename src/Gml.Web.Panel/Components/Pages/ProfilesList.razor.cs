using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using GmlAdminPanel.Models;
using GmlAdminPanel.Models.GmlApi;
using GmlAdminPanel.Models.Hierarchy;
using Microsoft.JSInterop;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.SignalR.Client;
using Radzen;
using Radzen.Blazor;
using File = System.IO.File;
using FileInfo = Radzen.FileInfo;

namespace GmlAdminPanel.Components.Pages
{
    public partial class ProfilesList
    {
        [Inject] protected IJSRuntime JSRuntime { get; set; }

        [Inject] protected NavigationManager NavigationManager { get; set; }

        [Inject] protected DialogService DialogService { get; set; }

        [Inject] protected TooltipService TooltipService { get; set; }

        [Inject] protected ContextMenuService ContextMenuService { get; set; }

        [Inject] protected NotificationService NotificationService { get; set; }

        [Inject] protected GmlAdminPanel.GmlApiService GmlApiService { get; set; }

        private HubConnection hubConnection;

        protected IEnumerable<GmlAdminPanel.Models.GmlApi.GetProfileDto> getProfileDtos;

        private IList<GmlAdminPanel.Models.GmlApi.GetProfileDto> _selectedProfiles = new List<GetProfileDto>();
        protected GmlAdminPanel.Models.GmlApi.GetProfileInfo ProfileInfo { get; set; }
        protected IList<System.IO.FileInfo> Files { get; set; }
        protected IList<Node> Directories { get; set; }

        protected RadzenUpload upload;


        List<string> filesToView;
        protected bool IsPackaging { get; set; }
        protected bool IsDownloading { get; set; }
        protected bool IsRemoving { get; set; }
        protected int ProcessPercentValue { get; set; }
        protected string ProcessFileName { get; set; }
        protected RadzenDataGrid<GmlAdminPanel.Models.Hierarchy.Node> grid;

        protected IList<GmlAdminPanel.Models.GmlApi.GetProfileDto> SelectedProfiles
        {
            get => _selectedProfiles;
            set
            {
                _selectedProfiles = value;

                LoadAdditionalData();
            }
        }

        async Task OnProgress(UploadProgressArgs args, string name)
        {
            await ShowConfirmationDialog(args.Files);
            // console.Log($"{args.Progress}% '{name}' / {args.Loaded} of {args.Total} bytes.");
            //
            // if (args.Progress == 100)
            // {
            //     foreach (var file in args.Files)
            //     {
            //         console.Log($"Uploaded: {file.Name} / {file.Size} bytes");
            //     }
            // }
        }

        async Task ShowConfirmationDialog(IEnumerable<FileInfo> argsFiles)
        {
            var result = await DialogService.OpenAsync<ConfirmFilePathDialog>(
                $"Load files to profile \"{ProfileInfo.ProfileName}\"",
                new Dictionary<string, object>
                {
                    { "Files", argsFiles.ToList() },
                    { "Upload", upload },
                    { "HttpClient", GmlApiService.HttpClient },
                },
                new DialogOptions
                {
                    Width = "700px",
                    Height = "512px",
                    Resizable = true,
                    Draggable = true
                }
            );
        }

        private async Task LoadAdditionalData()
        {
            if (IsDownloading)
                return;

            if (_selectedProfiles.Any() && _selectedProfiles.FirstOrDefault() is { } profileDto)
            {
                filesToView = new List<string>();
                ProfileInfo = null;

                ProfileInfo = await GmlApiService.GetProfileInfo(new ProfileCreateInfoDto
                {
                    ClientName = profileDto.Name,
                    GameAddress = "192.168.0.1",
                    GamePort = 25565,
                    RamSize = 4096,
                    SizeX = 1500,
                    SizeY = 900,
                    IsFullScreen = false,
                    UserAccessToken = "sergsecgrfsecgriseuhcygrshecngrysicugrbn7csewgrfcsercgser",
                    UserName = "GamerVII",
                    OsType = (int)OsType.Windows,
                    UserUuid = "31f5f477-53db-4afd-b88d-2e01815f4887"
                });

                ProfileInfo.Files = ProfileInfo.Files.OrderBy(c => c.Directory);

                Files = ProfileInfo.Files.Select(c => new System.IO.FileInfo(c.Directory)).ToList();


                filesToView = Files.Select(c => c.FullName.Split($"{ProfileInfo.ProfileName}/").LastOrDefault())
                    .Select(c => c.Split('/').First())
                    .Distinct()
                    .ToList();

                Directories = filesToView.Select(c => new FolderNode
                {
                    Name = c,
                    Directory = c
                }).Cast<Node>().ToList();

                StateHasChanged();
            }
        }

        private Task LoadAdditionalDataWindows()
        {
            return LoadAdditionalData(OsType.Windows);
        }

        private Task LoadAdditionalDataLinux()
        {
            return LoadAdditionalData(OsType.Linux);
        }

        private Task LoadAdditionalDataMacOs()
        {
            return LoadAdditionalData(OsType.OsX);
        }

        private async Task LoadAdditionalData(OsType osType)
        {
            var isSuccess = await DialogService.Confirm(
                $"It may take a long time to download the client, as well as overwrite the current settings, do you want to continue?",
                "Confirmation",
                new ConfirmOptions() { OkButtonText = "Yes", CancelButtonText = "No" });

            if (isSuccess is not true)
                return;

            IsDownloading = true;

            await hubConnection.SendAsync("Restore", ProfileInfo.ProfileName, (osType).ToString());

            return;
        }

        protected override async Task OnInitializedAsync()
        {
            getProfileDtos = await GmlApiService.GetProfiles();

            hubConnection = new HubConnectionBuilder()
                .WithUrl(NavigationManager.ToAbsoluteUri(
                    $"{GmlApiService.HttpClient.BaseAddress!.AbsoluteUri}ws/profiles/restore"))
                .Build();

            hubConnection.On<int>("ChangeProgress", async (progress) =>
            {
                if (ProcessPercentValue != progress)
                {
                    ProcessPercentValue = progress;
                    IsDownloading = true;
                    await InvokeAsync(StateHasChanged);
                }
            });

            hubConnection.On<string>("FileChanged", async (fileName) =>
            {
                if (!string.IsNullOrEmpty(fileName))
                {
                    ProcessFileName = fileName;
                    IsDownloading = true;
                    //await InvokeAsync(StateHasChanged);
                }
            });

            hubConnection.On("SuccessInstalled", async () =>
            {
                NotificationService.Notify(new NotificationMessage
                {
                    Severity = NotificationSeverity.Success,
                    Detail = "The profile has been successfully installed.",
                });

                IsDownloading = false;
            });


            await hubConnection.StartAsync();
        }

        protected override void OnInitialized()
        {
            base.OnInitialized();
        }

        void RowRender(RowRenderEventArgs<Node> args)
        {
            args.Expandable = !string.IsNullOrEmpty(args.Data.Directory) && args.Data?.GetType() != typeof(FileNode);
        }

        private async Task AddFileToWhiteList(GmlAdminPanel.Models.GmlApi.File file)
        {
            if (file != null && _selectedProfiles.Any() && _selectedProfiles.FirstOrDefault() is { } profileDto)
            {
                ProfileInfo.WhiteListFiles = await GmlApiService.AddWhiteList(new FileWhiteListDto
                {
                    ClientName = profileDto.Name,
                    FileHash = file.Hash
                });
            }
        }

        private async Task RemoveFileFromWhiteList(GmlAdminPanel.Models.GmlApi.File file)
        {
            if (_selectedProfiles.Any() && _selectedProfiles.FirstOrDefault() is { } profileDto)
            {
                ProfileInfo.WhiteListFiles = await GmlApiService.RemoveWhiteList(new FileWhiteListDto
                {
                    ClientName = profileDto.Name,
                    FileHash = file.Hash
                });
            }
        }

        void LoadChildData(DataGridLoadChildDataEventArgs<Node> args)
        {
            List<Node> childNodes = new List<Node>();

            var path = args.Item.GetHierarchyPath(args.Item);

            var directoryPath = $"{ProfileInfo.ProfileName}/{path}/";

            var children = ProfileInfo.Files
                .Where(c => c.Directory.Contains(directoryPath))
                .ToList();

            var files = children
                .Where(c => c.Directory.Split(directoryPath).Last().Count(c => c == '/') == 0)
                .Select(c => new FileNode
                {
                    Parent = args.Item,
                    Directory = c.Directory,
                    Name = c.Name,
                    Hash = c.Hash,
                    CurrentFile = c
                }).ToList();

            var directories = children.Except(files.Select(f => f.CurrentFile))
                .Where(c => c.Directory.Contains(directoryPath))
                .Select(c => c.Directory.Split(directoryPath).Last()).Select(c => c.Split('/').First()).Distinct()
                .ToList()
                .Select(c => new FolderNode
                {
                    Directory = c,
                    Name = c,
                    Parent = args.Item
                });

            childNodes.AddRange(files);
            childNodes.AddRange(directories);

            args.Data = childNodes;
        }

        protected override async Task OnAfterRenderAsync(bool firstRender)
        {
            base.OnAfterRender(firstRender);

            // await grid.ExpandRow(filesToView?.FirstOrDefault());
        }

        protected async Task RemoveSelectedProfile()
        {
            if (_selectedProfiles.Any() && _selectedProfiles.FirstOrDefault() is { } profileDto)
            {
                if (IsPackaging)
                {
                    NotificationService.Notify(new NotificationMessage
                    {
                        Severity = NotificationSeverity.Error,
                        Detail = "It is not possible to delete the profile during packaging",
                    });
                    return;
                }

                var isSuccess = await DialogService.Confirm(
                    $"Do you really want to delete the \"{profileDto.Name}\" profile?", "Confirmation",
                    new ConfirmOptions() { OkButtonText = "Yes", CancelButtonText = "No" });

                if (isSuccess is true)
                {
                    IsRemoving = true;
                    StateHasChanged();

                    await GmlApiService.RemoveProfile(new RemoveProfileDto
                    {
                        ClientName = profileDto.Name,
                        RemoveFiles = true
                    });

                    NotificationService.Notify(new NotificationMessage
                    {
                        Severity = NotificationSeverity.Success,
                        Detail = "The profile was successfully deleted",
                    });

                    SelectedProfiles = new List<GetProfileDto>();

                    ProfileInfo = null;

                    getProfileDtos = await GmlApiService.GetProfiles();

                    StateHasChanged();

                    IsRemoving = false;
                }
            }
        }

        protected async Task PackageSelectedProfile()
        {
            if (_selectedProfiles.Any() && _selectedProfiles.FirstOrDefault() is { } profileDto)
            {
                if (IsRemoving)
                {
                    NotificationService.Notify(new NotificationMessage
                    {
                        Severity = NotificationSeverity.Error,
                        Detail = "Profile packaging is not possible during deletion",
                    });
                    return;
                }

                var isSuccess = await DialogService.Confirm(
                    $"The client's packaging will take a long time, do you want to continue?", "Confirmation",
                    new ConfirmOptions() { OkButtonText = "Yes", CancelButtonText = "No" });

                if (isSuccess is not true)
                    return;

                IsPackaging = true;

                StateHasChanged();

                await GmlApiService.PackProfile(new PackProfileDto
                {
                    ClientName = profileDto.Name
                });

                NotificationService.Notify(new NotificationMessage
                {
                    Severity = NotificationSeverity.Success,
                    Detail = "The client has been successfully packaged",
                });
                IsPackaging = false;

                StateHasChanged();
            }
        }

        void LoadFiles(TreeExpandEventArgs args)
        {
            var directory = args.Value as string;

            args.Children.Data = Files.Where(c => c.FullName.Contains($"\\{directory}\\"))
                .Select(c => c.FullName.Split($"\\{directory}\\").LastOrDefault())
                .Select(c => c.Split('\\').First())
                .Distinct()
                .ToList();
            args.Children.Text = GetTextForNode;
            args.Children.HasChildren = (path) => Files
                .Where(c => c.FullName.Contains($"\\{directory}\\{path}\\"))
                .Select(c => c.FullName.Split($"\\{directory}\\{path}\\").LastOrDefault())
                .Any(c => !string.IsNullOrEmpty(c));
            args.Children.Template = FileOrFolderTemplate;
        }

        string GetTextForNode(object data)
        {
            return Path.GetFileName((string)data);
        }

        RenderFragment<RadzenTreeItem> FileOrFolderTemplate = (context) => builder =>
        {
            string path = context.Value as string;
            bool isDirectory = Path.GetExtension(path)?.Length < 3;

            builder.OpenComponent<RadzenIcon>(0);
            builder.AddAttribute(1, nameof(RadzenIcon.Icon), isDirectory ? "folder" : "insert_drive_file");
            builder.CloseComponent();
            builder.AddContent(3, context.Text);
        };
    }

    public class FileItem
    {
        public string Name { get; set; }
        public string Directory { get; set; }
        public long Size { get; set; }
        public string Hash { get; set; }
        public List<FileItem> Children { get; set; }
    }


    public enum OsType
    {
        Undefined = 0,
        Linux = 1,
        OsX = 2,
        Windows = 3,
    }

    public class FileDataItem
    {
        public string Name { get; set; }
        public bool IsDirectory { get; set; }
        public List<FileItem> Children { get; set; } = new List<FileItem>();
    }
}
