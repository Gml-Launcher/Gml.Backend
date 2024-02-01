using System;
using System.Net;

namespace Gml.WebApi.Models.Dtos.Response;

public class ResponseMessage
{
    public string Status { get; set; } = null!;
    public int StatusCode { get; set; }
    public string Message { get; set; }= null!;

    public static ResponseMessage Create(string message, HttpStatusCode statusCode)
    {
        return new ResponseMessage
        {
            Message = message,
            Status = statusCode.ToString(),
            StatusCode = (int)statusCode
        };
    }

    public static ResponseMessage<T> Create<T>(T content, HttpStatusCode statusCode, string? message)
    {
        return new ResponseMessage<T>
        {
            Message = message ?? string.Empty,
            Status = statusCode.ToString(),
            StatusCode = (int)statusCode,
            Data = content
        };
    }
}

public class ResponseMessage<T> : ResponseMessage
{
    public T? Data { get; set; }

}
