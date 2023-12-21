using System;
using System.Text;
using System.Text.Json;

namespace GmlAdminPanel.Models
{
    public class OAuthResponse
    {
        private OAuthResponse(string json)
        {
            using var document = JsonDocument.Parse(json);

            var root = document.RootElement;

            AccessToken = GetString(root, "access_token");
            RefreshToken = GetString(root, "refresh_token");
            ExpiresIn = GetInt(root, "expires_in");
            ExpiresAt = DateTime.UtcNow.AddSeconds(ExpiresIn);
            Scope = GetString(root, "scope");
            TokenType = GetString(root, "token_type");
            Error = GetError(root);
        }

        public OAuthResponse()
        {
        }

        private static string GetError(JsonElement element)
        {
            var error = GetString(element, "error");

            if (error == null)
            {
                return null;
            }

            var result = new StringBuilder("OAuth token endpoint failure: ");
            result.Append(error);

            if (element.TryGetProperty("error_description", out var errorDescription))
            {
                result.Append(";Description=");
                result.Append(errorDescription);
            }

            if (element.TryGetProperty("error_uri", out var errorUri))
            {
                result.Append(";Uri=");
                result.Append(errorUri);
            }

            return result.ToString();
        }

        private static string GetString(JsonElement element, string name)
        {
            return element.TryGetProperty(name, out var property) ? property.GetString() : null;
        }

        private static int GetInt(JsonElement element, string name)
        {
            return element.TryGetProperty(name, out var property) ? property.GetInt32() : 0;
        }

        public OAuthResponse Refresh(string json)
        {
            var response = new OAuthResponse(json);

            response.RefreshToken = RefreshToken;

            return response;
        }

        public static OAuthResponse Success(string json)
        {
            return new OAuthResponse(json);
        }

        public static OAuthResponse Failure(string json)
        {
            try
            {
                return new OAuthResponse(json);
            } 
            catch (JsonException)
            {
                return new OAuthResponse { Error = json };
            }
        }

        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public DateTime ExpiresAt { get; set; }
        public int ExpiresIn { get; set; }
        public string Scope { get; set; }
        public string TokenType { get; set; }
        public string Error { get; set; }
        public bool IsSuccess => Error == null;
    }
}