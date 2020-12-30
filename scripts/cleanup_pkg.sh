#!usr/bin/env bash

echo "Executing cleanup_pkg.sh"

echo "Removing deployment zip"
rm -rf $path_module/$lambda_package_zip

echo "Removing deployment package"
rm -rf $path_module/$lambda_package_dir

echo "Removing lambda environment"
rm -rf $path_module/$lambda_env

echo "Finished script Execution!"