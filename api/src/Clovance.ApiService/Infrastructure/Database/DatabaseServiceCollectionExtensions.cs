using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Clovance.ApiService.Infrastructure.Database;

public static class DatabaseServiceCollectionExtensions
{
    public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("clovance-database");

        // Npgsql 10 defaults to GssEncryptionMode=Prefer, so against a GSS-capable PostgreSQL
        // server the .NET runtime tries to load libgssapi_krb5.so.2 (not shipped in the
        // official .NET images) and writes an uncatchable error to stderr on every physical
        // connection. Kerberos is not used here, so disable GSS encryption unless the
        // connection string already sets it explicitly (Npgsql issue npgsql#6360).
        const string gssEncryptionMode = "GSS Encryption Mode=";
        if (connectionString is not null &&
            !connectionString.Contains(gssEncryptionMode, StringComparison.OrdinalIgnoreCase))
        {
            connectionString = $"{connectionString};{gssEncryptionMode}Disable";
        }

        Action<DbContextOptionsBuilder> configureDbContext = options =>
        {
            options
                .UseNpgsql(
                    connectionString,
                    npgsqlOptions =>
                    {
                        npgsqlOptions.MigrationsHistoryTable("ef_migrations_history");
                    })
                .UseSnakeCaseNamingConvention();
        };

        services.AddDbContext<ClovanceDbContext>(
            configureDbContext,
            contextLifetime: ServiceLifetime.Scoped,
            optionsLifetime: ServiceLifetime.Singleton);

        services.AddScoped<ISetupTransactionProvider, PostgresSetupTransactionProvider>();
        services.AddScoped<ITransactionDescriptionSearch, PostgresTransactionDescriptionSearch>();

        services.AddDbContextFactory<ClovanceDbContext>(configureDbContext);

        services.AddHealthChecks()
            .AddDbContextCheck<ClovanceDbContext>("database", tags: ["ready"]);

        services
          .AddIdentityCore<ApplicationUser>(options =>
          {
              options.User.RequireUniqueEmail = true;
              options.Password.RequireDigit = true;
              options.Password.RequiredLength = 12;
              options.Password.RequireNonAlphanumeric = true;
              options.Password.RequireUppercase = true;
              options.Password.RequireLowercase = true;
              options.Lockout.MaxFailedAccessAttempts = 5;
              options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
          })
          .AddRoles<IdentityRole<Guid>>()
          .AddSignInManager()
          .AddEntityFrameworkStores<ClovanceDbContext>()
          .AddDefaultTokenProviders();

        return services;
    }
}
