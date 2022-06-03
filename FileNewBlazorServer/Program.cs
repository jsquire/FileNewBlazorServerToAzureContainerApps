using Azure.Storage.Blobs;
using FileNewBlazorServer.Data;
using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);

// make sure the blob storage container exists
var storageConnectionString = builder.Configuration.GetValue<string>("AZURE_STORAGE_CONNECTIONSTRING");
var blobContainerName = builder.Configuration.GetValue<string>("KEYS_BLOB_CONTAINER");
var container = new BlobContainerClient(storageConnectionString, blobContainerName);
await container.CreateIfNotExistsAsync();

builder.Services.AddDataProtection()
                .PersistKeysToAzureBlobStorage(storageConnectionString, blobContainerName, "keys.xml");

// Add services to the container.
var signalrConnectionString = builder.Configuration.GetValue<string>("AZURE_SIGNALR_CONNECTIONSTRING");
builder.Services.AddRazorPages();
builder.Services.AddSignalR().AddAzureSignalR(signalrConnectionString);
builder.Services.AddServerSideBlazor();
builder.Services.AddSingleton<WeatherForecastService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}


app.UseStaticFiles();
app.UseRouting();
app.MapBlazorHub();
app.MapFallbackToPage("/_Host");
app.Run();
