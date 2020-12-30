#!usr/bin/env bash

echo "Executing create_pkg.sh"

cd $path_module
mkdir $lambda_package_dir


echo "Creating virtualenv"
$runtime -m venv $lambda_env
source $path_module/$lambda_env/bin/activate

FILE=$path_module/$source_code_dir/requirements.txt

if [ -f "$FILE" ]; then
  echo "Installing dependencies"
  pip install -r "$FILE"
else
  echo "Requirements.txt does not exist... moving on"
fi

deactivate

echo "Creating deployment package"
cd $lambda_env/lib/$runtime/site-packages/
cp -r . $path_module/$lambda_package_dir
cp -r $path_module/$source_code_dir/ $path_module/$lambda_package_dir

echo "Finished script Execution!"
