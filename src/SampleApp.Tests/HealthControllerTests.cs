using Microsoft.AspNetCore.Mvc;
using SampleApp.Controllers;
using Xunit;

namespace SampleApp.Tests;

public class HealthControllerTests
{
    [Fact]
    public void Get_ReturnsContentResult()
    {
        // Arrange
        var controller = new HealthController();

        // Act
        var result = controller.Get();

        // Assert
        var contentResult = Assert.IsType<ContentResult>(result);
        Assert.Equal("text/html", contentResult.ContentType);
        Assert.Contains("SYSTEM HEALTHY", contentResult.Content);
    }
}