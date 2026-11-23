using Aspire.Hosting.Docker.Resources.ServiceNodes;

var builder = DistributedApplication.CreateBuilder(args);

var isTestEnvironment = builder.Environment.EnvironmentName == "Testing";
var isRunMode = builder.ExecutionContext.IsRunMode;

// Docker Compose publish only: the host interface each published port binds to is read
// from the environment at deploy time. Defaults keep http://ip:port working; set the
// variable to 127.0.0.1 to reach the service only from the host (e.g. behind a reverse proxy).
const string frontendBindAddress = "${CLOVANCE_BIND_ADDRESS:-0.0.0.0}";
const string dashboardBindAddress = "${CLOVANCE_DASHBOARD_BIND_ADDRESS:-0.0.0.0}";

builder.AddDockerComposeEnvironment("env")
    .ConfigureComposeFile(composeFile =>
    {
        if (composeFile.Services.TryGetValue("env-dashboard", out var dashboard))
        {
            dashboard.Ports = [$"{dashboardBindAddress}::18888"];
        }
    });

var postgresUsername = builder.AddParameter("postgres-username");
var postgresPassword = builder.AddParameter("postgres-password", secret: true);

// --- SMTP ---
var smtpHost = builder.AddParameter("smtp-host");
var smtpPort = builder.AddParameter("smtp-port");
var smtpUsername = builder.AddParameter("smtp-username");
var smtpPassword = builder.AddParameter("smtp-password", secret: true);
var smtpFromAddress = builder.AddParameter("smtp-from-address");
var smtpFromName = builder.AddParameter("smtp-from-name");

var frontendBaseUrl = builder.AddParameter("frontend-base-url");

var volumeSourcePath = builder.AddParameter("volume-source-path");

// Use different resource names for testing vs development to avoid container conflicts
var postgresResourceName =
    isTestEnvironment ? "clovance-postgres-test" : "clovance-postgres";

var postgres = builder
    .AddPostgres(
        postgresResourceName,
        userName: postgresUsername,
        password: postgresPassword)
    .WithEnvironment("POSTGRES_DB", "clovance-database");

// Development only:
// Persist PostgreSQL using an Aspire-managed Docker volume.
//
// This is deliberately NOT added during publish, otherwise the generated
// Docker Compose would contain both the named volume and the production bind mount.
if (isRunMode && !isTestEnvironment)
{
    postgres
        .WithDataVolume()
        .WithLifetime(ContainerLifetime.Persistent)
        .WithPgWeb();
}

// Docker Compose publish only:
// Use bind mounts configured through VOLUME_SOURCE_PATH.
postgres.PublishAsDockerComposeService((resource, service) =>
{
    service.Restart = "unless-stopped";

    service.Volumes.Add(new Volume
    {
        Name = "clovance-postgres-data",
        Source = $"{volumeSourcePath.AsEnvironmentPlaceholder(resource)}/postgres",
        Target = "/var/lib/postgresql",
        Type = "bind",
        ReadOnly = false
    });
});

// Add the default database to the application model so that it can be referenced by other resources.
var database = postgres.AddDatabase("clovance-database");

var jwtKeyFilePath =
    builder.Configuration["Jwt:KeyFilePath"] ?? "/home/app/jwt.key";

var apiService = builder
    .AddDotnetProject("clovance-apiservice", "../../src/Clovance.ApiService/Clovance.ApiService.csproj")
    .WithReference(database)
    .WithEnvironment("ASPNETCORE_ENVIRONMENT", builder.Environment.EnvironmentName)
    .WithEnvironment("Jwt__KeyFilePath", jwtKeyFilePath)
    .WithEnvironment("Smtp__Host", smtpHost)
    .WithEnvironment("Smtp__Port", smtpPort)
    .WithEnvironment("Smtp__Username", smtpUsername)
    .WithEnvironment("Smtp__Password", smtpPassword)
    .WithEnvironment("Smtp__FromAddress", smtpFromAddress)
    .WithEnvironment("Smtp__FromName", smtpFromName)
    .WithEnvironment("Frontend__BaseUrl", frontendBaseUrl)
    .WaitFor(database)
    .WithHttpHealthCheck("/health")
    .PublishAsDockerComposeService((resource, service) =>
    {
        service.Volumes.Add(new Volume
        {
            Name = "clovance-jwt-keys",
            Source = $"{volumeSourcePath.AsEnvironmentPlaceholder(resource)}/jwt",
            Target = "/home/app",
            Type = "bind",
            ReadOnly = false
        });

        service.Restart = "unless-stopped";
    });

builder
    .AddJavaScriptApp(
        "clovance-frontend",
        "../../../frontend",
        runScriptName: "start")
    .WithPnpm(installArgs: ["--frozen-lockfile", "--ignore-scripts"])
    .WithReference(apiService)
    .WaitFor(apiService)
    .WithHttpEndpoint(port: 7000, env: "PORT")
    .WithHttpHealthCheck("/healthz.txt")
    .WithExternalHttpEndpoints()
    .PublishAsDockerFile(container => container
        .WithEntrypoint("/docker-entrypoint.sh")
        .WithArgs("nginx", "-g", "daemon off;"))
    .PublishAsDockerComposeService((resource, service) =>
    {
        service.Restart = "unless-stopped";
        service.Ports = [$"{frontendBindAddress}:7000:7000"];
    });

await builder.Build().RunAsync();
