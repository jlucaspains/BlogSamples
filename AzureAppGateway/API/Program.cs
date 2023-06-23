var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "The app is live and running");
app.MapGet("/health", () => "Healthy!");

app.Run();