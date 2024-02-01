using System;

namespace Gml.WebApi.Models.Dtos.Users
{
    public class AuthDto
    {
        public string Login { get; set; } = null!;
        public string Password { get; set; } = null!;
    }
}
