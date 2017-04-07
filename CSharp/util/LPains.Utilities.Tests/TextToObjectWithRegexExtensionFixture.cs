
using Xunit;
using LPains.Utilities;

namespace LPains.Utilities.Tests
{
    public class ProductPrice
    {
        public string ProductCode { get; set; }
        public decimal Price { get; set; }
    }

    public class TextToObjectWithRegexExtensionFixture
    {
        [Fact]
        public void Test()
        {
            var result = "123456 . 22.2".ParseToObject<ProductPrice>("(?<ProductCode>\\d{6}) \\. (?<Price>\\d{2}\\.\\d)");
            Assert.NotNull(result);
            Assert.Equal("123456", result.ProductCode);
            Assert.Equal(22.2M, result.Price);

            var result2 = "65432133.3".ParseToObject<ProductPrice>("(?<ProductCode>\\d{6})(?<Price>\\d{2}\\.\\d)");
            Assert.NotNull(result);
            Assert.Equal("654321", result2.ProductCode);
            Assert.Equal(33.3M, result2.Price);

            var result3 = "444.4524142".ParseToObject<ProductPrice>("(?<Price>\\d{3}\\.\\d)(?<ProductCode>\\d{6})");
            Assert.NotNull(result);
            Assert.Equal("524142", result3.ProductCode);
            Assert.Equal(444.4M, result3.Price);

            var result4 = "555.5".ParseToObject<ProductPrice>("(?<Price>\\d{3}\\.\\d)");
            Assert.NotNull(result);
            Assert.Null(result4.ProductCode);
            Assert.Equal(555.5M, result4.Price);
        }
    }
}
