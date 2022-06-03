using Azure.Identity;
using Azure.Storage.Blobs;
using FileNewBlazorServer.Data;
using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);

// make sure the blob storage container exists
var storageConnectionString = builder.Configuration.GetValue<string>("AZURE_STORAGE_CONNECTIONSTRING");
var blobContainerName = builder.Configuration.GetValue<string>("KEYS_BLOB_CONTAINER");
var container = new BlobContainerClient(storageConnectionString, blobContainerName);
await container.CreateIfNotExistsAsync();

// wire up the data protection services and connect to keyvault
var keyVaultName = builder.Configuration.GetValue<string>("KEY_VAULT_NAME");
builder.Services.AddDataProtection()
                .PersistKeysToAzureBlobStorage(storageConnectionString, blobContainerName, "keys.xml")
                .ProtectKeysWithAzureKeyVault(new Uri($"https://{keyVaultName}.vault.azure.net/keys/dataprotection"), new DefaultAzureCredential());

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
