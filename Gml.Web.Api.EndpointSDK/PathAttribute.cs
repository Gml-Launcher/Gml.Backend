using System;

namespace Gml.Web.Api.EndpointSDK;

public class PathAttribute(string? method, string? path) : Attribute
{
    public string? Method { get; set; } = method;
    public string? Path { get; set; } = path;
}
