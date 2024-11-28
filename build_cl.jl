using Pkg
using PackageCompiler

# Ensure required packages are installed
required_packages = ["JSON", "Nettle", "Sockets", "Base64"]

for package in required_packages
    if !haskey(Pkg.project().dependencies, package)
        Pkg.add(package)
    end
end

# Create executable from Krypto module
create_app(".", "build", precompile_execution_file="kauma", force=true)

# Make the compiled executable executable
chmod(joinpath("build", "bin", "Krypto"), 0o755)

# Create symlink for easier access
symlink_path = "Krypto"
if islink(symlink_path)
    rm(symlink_path)
end
symlink(joinpath("build", "bin", "Krypto"), symlink_path)

println("Build complete! You can now run ./Krypto sample.json")