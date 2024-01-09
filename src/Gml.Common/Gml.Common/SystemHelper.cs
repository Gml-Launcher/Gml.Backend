using System;
using System.IO;
using System.Security.Cryptography;

namespace Gml.Common
{
    public static class SystemHelper
    {
        public static string CalculateFileHash(string filePath, HashAlgorithm algorithm)
        {
            using var fileStream = File.OpenRead(filePath);
            var hashBytes = algorithm.ComputeHash(fileStream);

            return BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
        }
    }
}
