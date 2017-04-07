using System;
using System.Globalization;
using System.Reflection;
using System.Text.RegularExpressions;

namespace LPains.Utilities
{
    /// <summary>
    /// Provides a extension method for transforming string to object using a regular expression as parser
    /// </summary>
    public static class TextToObjectWithRegexExtension
    {
        /// <summary>
        /// Creates an instance of <typeparamref name="TData"/> and assigns its properties based on captures from regular expression in <paramref name="regularExpression"/>
        /// </summary>
        /// <typeparam name="TData">Result type. Must be newable.</typeparam>
        /// <param name="data">string to be parsed</param>
        /// <param name="regularExpression">regular expression with named group captures used to parse <paramref name="data"/> into <typeparamref name="TData"/></param>
        /// <returns></returns>
       public static TData ParseToObject<TData>(this string data, string regularExpression) where TData: new()
        {
            if (string.IsNullOrEmpty(data)) throw new ArgumentNullException(nameof(data));
            if (string.IsNullOrEmpty(regularExpression)) throw new ArgumentNullException(nameof(regularExpression));

            var result = new TData();
            var properties = result.GetType().GetProperties(BindingFlags.Public | BindingFlags.Instance);
            var groups = Regex.Match(data, regularExpression).Groups;

            foreach (var propertyToSet in properties)
            {
                if (propertyToSet.Name.ToUpper(CultureInfo.InvariantCulture) == "RAWINPUT")
                {
                    propertyToSet.SetValue(result, data, null);
                    continue;
                }

                var group = groups[propertyToSet.Name];
                var propertyValue = group.Success ? group.Value : null;
                if ((!propertyToSet.PropertyType.IsValueType || string.IsNullOrEmpty(propertyValue)) && propertyToSet.PropertyType != typeof(string)) continue;

                var value = propertyToSet.PropertyType.IsEnum
                    ? Enum.Parse(propertyToSet.PropertyType, propertyValue)
                    : Convert.ChangeType(propertyValue, propertyToSet.PropertyType, CultureInfo.InvariantCulture);

                propertyToSet.SetValue(result, value, null);
            }

            return result;
        }
    }
}
