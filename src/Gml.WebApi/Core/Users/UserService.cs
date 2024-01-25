using Newtonsoft.Json;

namespace Gml.WebApi.Core.Users;

public class AuthUser
{
    public string Login { get; set; }

    [JsonIgnore]
    public string Password { get; set; }
}

public interface IUserService
{
    Task<AuthUser?> Authenticate(string username, string password);
    Task<IEnumerable<AuthUser>> GetAll();
}

public class UserService : IUserService
{
    private List<AuthUser> _users =
    [
        new AuthUser
        {
            Password = "admin",
            Login = "admin"
        }
    ];

    public Task<AuthUser?> Authenticate(string username, string password)
    {
        return Task.FromResult(_users.SingleOrDefault(x => x.Login == username && x.Password == password));
    }

    public async Task<IEnumerable<AuthUser>> GetAll()
    {
        return await Task.Run(() => _users);
    }
}
