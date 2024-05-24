using System.Text.RegularExpressions;
using FluentValidation;
using Gml.Web.Api.Plugins.Servers.Models.DTOs;

namespace Gml.Web.Api.Plugins.Servers.Validators;

public class ServerCreateValidator : AbstractValidator<AddServerDto>
{
    public ServerCreateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Поле имени сервера обязательно для заполнения.")
            .Length(1, 100).WithMessage("Название сервера должно содержать от 1 до 100 символов.");

        RuleFor(x => x.Address)
            .NotEmpty().WithMessage("Поле адреса обязательно для заполнения.")
            .Matches(new Regex(@"^\S+$")).WithMessage("Адрес не должен содержать пробелы")
            .Length(1, 100).WithMessage("Адрес должен содержать от 1 до 100 символов.");

        RuleFor(x => x.Port)
            .InclusiveBetween(1, 65535).WithMessage("Порт должен быть между 1 и 65535.");

        RuleFor(x => x.ProfileName)
            .NotEmpty().WithMessage("Поле имени профиля обязательно для заполнения.")
            .Length(1, 50).WithMessage("Имя профиля должно содержать от 1 до 50 символов.");
    }
}
